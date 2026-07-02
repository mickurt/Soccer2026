#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import csv
import json
import datetime
import urllib.request
import argparse
import random
import time
import subprocess

# Firebase & APNs imports
try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    firebase_admin = None
    print("Avertissement : firebase_admin non installé.")

try:
    import jwt
except ImportError:
    jwt = None
    print("Avertissement : PyJWT non installé.")

try:
    import httpx
except ImportError:
    httpx = None
    print("Avertissement : httpx non installé.")

import re
import base64

def extract_player_name(description, event_type):
    desc = description.strip()
    # Nettoyage des préfixes selon la langue
    if event_type == 0:  # Goal
        desc = re.sub(r'^(But de|Goal by|But contre son camp de|Own goal by|Penalty marqué par|Penalty scored by)\s+', '', desc, flags=re.IGNORECASE)
    # Chercher ce qui est avant la première parenthèse
    match = re.match(r'^([^(\n]+)\s*\(', desc)
    if match:
        return match.group(1).strip()
    return desc

def parse_kickoff_time(kickoff_str):
    # Exemple: "2026-06-11 15:00:00-06" -> ISO format
    iso_str = kickoff_str.replace(" ", "T")
    if len(iso_str) == 22: # Si le fuseau horaire est comme -06 au lieu de -06:00
        iso_str += ":00"
    # Convert trailing +HHMM or -HHMM to +HH:MM for fromisoformat in older Python versions
    if len(iso_str) >= 5 and (iso_str[-5] == '+' or iso_str[-5] == '-') and iso_str[-3] != ':':
        iso_str = iso_str[:-2] + ':' + iso_str[-2:]
    dt = datetime.datetime.fromisoformat(iso_str)
    return dt.astimezone(datetime.timezone.utc)

def load_teams(teams_csv_path):
    teams = {}
    if not os.path.exists(teams_csv_path):
        print(f"Erreur : Fichier teams.csv introuvable à {teams_csv_path}")
        return teams
        
    with open(teams_csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            fifa_code = row.get('fifa_code', '').strip()
            team_id = row.get('id', '').strip()
            if fifa_code and team_id:
                teams[fifa_code] = int(team_id)
    return teams

def load_matches(matches_csv_path):
    local_matches = []
    if not os.path.exists(matches_csv_path):
        print(f"Erreur : Fichier matches.csv introuvable à {matches_csv_path}")
        return local_matches
        
    with open(matches_csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            try:
                local_matches.append({
                    'id': int(row['id']),
                    'match_number': int(row['match_number']),
                    'home_team_id': int(row['home_team_id']) if row['home_team_id'] else None,
                    'away_team_id': int(row['away_team_id']) if row['away_team_id'] else None,
                    'kickoff_utc': parse_kickoff_time(row['kickoff_at']),
                    'match_label': row['match_label']
                })
            except Exception as e:
                print(f"Erreur de parsing pour le match ID {row.get('id')}: {e}")
    return local_matches

def find_local_match(api_match, local_matches, teams, matched_ids):
    home_obj = api_match.get('Home')
    away_obj = api_match.get('Away')
    
    home_tla = home_obj.get('Abbreviation') if home_obj else None
    away_tla = away_obj.get('Abbreviation') if away_obj else None
    
    # Normalisation pour l'Uruguay (URY -> URU) et Curaçao (CUW -> CUR)
    if home_tla == 'URY': home_tla = 'URU'
    if away_tla == 'URY': away_tla = 'URU'
    if home_tla == 'CUW': home_tla = 'CUR'
    if away_tla == 'CUW': away_tla = 'CUR'
    
    api_home_id = teams.get(home_tla) if home_tla else None
    api_away_id = teams.get(away_tla) if away_tla else None
    
    api_date_str = api_match.get('Date')
    # Normalisation du fuseau horaire Z -> +00:00
    if api_date_str.endswith('Z'):
        api_date_str = api_date_str[:-1] + '+00:00'
    api_dt = datetime.datetime.fromisoformat(api_date_str).astimezone(datetime.timezone.utc)
    
    # 1. Recherche par correspondance exacte des deux équipes (idéal pour la phase de groupes)
    if api_home_id is not None and api_away_id is not None:
        for m in local_matches:
            if m['id'] in matched_ids:
                continue
            if m['home_team_id'] == api_home_id and m['away_team_id'] == api_away_id:
                return m
                
    # 2. Recherche par heure de coup d'envoi (tolérance de 12 heures pour les décalages de date/fuseau dans le calendrier)
    candidates = []
    for m in local_matches:
        if m['id'] in matched_ids:
            continue
        diff_seconds = abs((m['kickoff_utc'] - api_dt).total_seconds())
        if diff_seconds <= 43200:  # 12 heures
            candidates.append((diff_seconds, m))
            
    if candidates:
        candidates.sort(key=lambda x: x[0])
        # Priorité aux matchs de type knockout (qui ont un ID >= 73)
        knockouts = [c for c in candidates if int(c[1]['id']) >= 73]
        if knockouts:
            return knockouts[0][1]
        return candidates[0][1]
        
    return None

def fetch_api_updates(api_key, local_matches, teams):
    print("Connexion à l'API officielle FIFA...")
    url = "https://api.fifa.com/api/v3/calendar/matches?idSeason=285023&idCompetition=17&language=fr&count=500"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    }
    req = urllib.request.Request(url, headers=headers)
    
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode('utf-8'))
    except Exception as e:
        print(f"Erreur lors de la requête API FIFA : {e}")
        return None
        
    api_matches = data.get('Results', [])
    print(f"Reçu {len(api_matches)} matchs de l'API FIFA.")
    
    updates = []
    matched_count = 0
    matched_ids = set()
    
    for api_m in api_matches:
        status_val = api_m.get('MatchStatus')
        
        # Mappage des statuts (0: Finished, 3: Live, les autres: Scheduled)
        if status_val == 0:
            status = 'Finished'
        elif status_val == 3:
            status = 'Live'
        else:
            status = 'Scheduled'
            
        local_m = find_local_match(api_m, local_matches, teams, matched_ids)
        if local_m:
            matched_ids.add(local_m['id'])
        if local_m:
            home_score = api_m.get('HomeTeamScore')
            away_score = api_m.get('AwayTeamScore')
            
            # Si le match n'a pas commencé, le score peut être None
            if home_score is None: home_score = 0
            if away_score is None: away_score = 0
            
            home_obj = api_m.get('Home')
            away_obj = api_m.get('Away')
            
            home_team_code = home_obj.get('Abbreviation') if home_obj else ''
            away_team_code = away_obj.get('Abbreviation') if away_obj else ''
            
            if home_team_code == 'URY': home_team_code = 'URU'
            if away_team_code == 'URY': away_team_code = 'URU'
            if home_team_code == 'CUW': home_team_code = 'CUR'
            if away_team_code == 'CUW': away_team_code = 'CUR'
            
            # Récupérer la timeline si le match est en cours ou terminé
            id_comp = api_m.get('IdCompetition')
            id_season = api_m.get('IdSeason')
            id_stage = api_m.get('IdStage')
            id_match = api_m.get('IdMatch')
            home_team_id = home_obj.get('IdTeam') if home_obj else None
            away_team_id = away_obj.get('IdTeam') if away_obj else None
            
            events_list = []
            if status in ['Live', 'Finished'] and id_comp and id_season and id_stage and id_match:
                timeline_url = f"https://api.fifa.com/api/v3/timelines/{id_comp}/{id_season}/{id_stage}/{id_match}?language=fr"
                timeline_req = urllib.request.Request(timeline_url, headers=headers)
                try:
                    with urllib.request.urlopen(timeline_req, timeout=10) as t_resp:
                        t_data = json.loads(t_resp.read().decode('utf-8'))
                        for ev in t_data.get('Event', []):
                            t_type = ev.get('Type')
                            # 0: Goal (But!), 2: Yellow Card, 3: Red Card
                            if t_type in [0, 2, 3]:
                                ev_type = "goal" if t_type == 0 else ("yellow_card" if t_type == 2 else "red_card")
                                minute = ev.get('MatchMinute') or ""
                                ev_team_id = ev.get('IdTeam')
                                
                                team_mapping = "unknown"
                                if ev_team_id == home_team_id:
                                    team_mapping = "home"
                                elif ev_team_id == away_team_id:
                                    team_mapping = "away"
                                    
                                player_name = "Joueur"
                                desc_list = ev.get('EventDescription') or []
                                if desc_list:
                                    description = desc_list[0].get('Description') or ""
                                    player_name = extract_player_name(description, t_type)
                                    
                                events_list.append({
                                    'minute': minute,
                                    'type': ev_type,
                                    'player': player_name,
                                    'team': team_mapping
                                })
                except Exception as ex:
                    print(f"Erreur de lecture timeline pour le match {id_match}: {ex}")
            
            events_base64 = ""
            if events_list:
                import base64
                events_json = json.dumps(events_list)
                events_base64 = base64.b64encode(events_json.encode('utf-8')).decode('utf-8')
            
            updates.append({
                'id': local_m['id'],
                'status': status,
                'home_score': home_score,
                'away_score': away_score,
                'home_team_code': home_team_code,
                'away_team_code': away_team_code,
                'kickoff_utc': api_m.get('Date') or '',
                'match_time': api_m.get('MatchTime') or '',
                'events': events_base64
            })
            matched_count += 1
        else:
            home_obj = api_m.get('Home')
            away_obj = api_m.get('Away')
            h_name = home_obj.get('TeamName', [{}])[0].get('Description') if home_obj and home_obj.get('TeamName') else 'N/A'
            a_name = away_obj.get('TeamName', [{}])[0].get('Description') if away_obj and away_obj.get('TeamName') else 'N/A'
            print(f"Avertissement : Impossible de mapper le match de l'API {h_name} vs {a_name} ({api_m.get('Date')})")
            
    print(f"Mappage terminé : {matched_count} matchs mappés sur les matches locaux.")
    return updates

def generate_mock_events(home_score, away_score, match_id, status, elapsed_minutes, home_code, away_code):
    import random
    # Utiliser une graine stable pour que les évènements ne changent pas à chaque rafraîchissement
    # mais dépendent uniquement de l'ID du match et des scores actuels
    random.seed(match_id * 1000 + home_score + away_score)
    
    events = []
    
    # Générer les buts à domicile
    for i in range(home_score):
        minute = random.randint(1, elapsed_minutes)
        events.append({
            'minute': f"{minute}'",
            'type': 'goal',
            'player': f"Buteur {home_code}",
            'team': 'home'
        })
        
    # Générer les buts à l'extérieur
    for i in range(away_score):
        minute = random.randint(1, elapsed_minutes)
        events.append({
            'minute': f"{minute}'",
            'type': 'goal',
            'player': f"Buteur {away_code}",
            'team': 'away'
        })
        
    # Générer des cartons jaunes aléatoires (entre 0 et 3)
    num_yellow = random.randint(0, 3)
    for i in range(num_yellow):
        minute = random.randint(1, elapsed_minutes)
        team = 'home' if random.random() < 0.5 else 'away'
        code = home_code if team == 'home' else away_code
        events.append({
            'minute': f"{minute}'",
            'type': 'yellow_card',
            'player': f"Joueur {code}",
            'team': team
        })
        
    # 15% de chance d'avoir un carton rouge
    if random.random() < 0.15:
        minute = random.randint(1, elapsed_minutes)
        team = 'home' if random.random() < 0.5 else 'away'
        code = home_code if team == 'home' else away_code
        events.append({
            'minute': f"{minute}'",
            'type': 'red_card',
            'player': f"Exclu {code}",
            'team': team
        })
        
    # Trier les évènements par minute chronologiquement
    def get_min_val(ev):
        try:
            return int(ev['minute'].replace("'", ""))
        except:
            return 0
    events.sort(key=get_min_val)
    return events

def run_simulation(sim_date_str, local_matches, base_dir=None):
    if sim_date_str:
        try:
            # Format attendu: AAAA-MM-JJ ou AAAA-MM-JJTHH:MM:SS
            if 'T' not in sim_date_str and ' ' not in sim_date_str:
                sim_date_str += "T12:00:00"
            sim_date_str = sim_date_str.replace(" ", "T")
            if '+' not in sim_date_str and '-' not in sim_date_str and not sim_date_str.endswith('Z'):
                sim_date_str += "+00:00"
            sim_dt = datetime.datetime.fromisoformat(sim_date_str).astimezone(datetime.timezone.utc)
        except Exception as e:
            print(f"Erreur de format de date de simulation ({sim_date_str}). Utilisation de la date actuelle. Erreur: {e}")
            sim_dt = datetime.datetime.now(datetime.timezone.utc)
    else:
        now = datetime.datetime.now(datetime.timezone.utc)
        # Match 1 commence le 2026-06-11 UTC. Si nous sommes avant, on simule au 2026-06-12 pour voir des scores
        start_date = datetime.datetime(2026, 6, 11, 21, 0, 0, tzinfo=datetime.timezone.utc)
        if now < start_date:
            sim_dt = datetime.datetime(2026, 6, 12, 22, 0, 0, tzinfo=datetime.timezone.utc)
            print(f"Date réelle avant le tournoi. Simulation au jour J+1 du tournoi : {sim_dt}")
        else:
            sim_dt = now
            print(f"Simulation basée sur la date réelle : {sim_dt}")
            
    # Charger les codes d'équipes pour générer des évènements plus réalistes
    teams_map = {}
    if base_dir:
        teams_csv_path = os.path.join(base_dir, 'teams.csv')
        if os.path.exists(teams_csv_path):
            try:
                with open(teams_csv_path, 'r', encoding='utf-8') as f:
                    reader = csv.DictReader(f)
                    for row in reader:
                        teams_map[int(row['id'])] = {
                            'code': row['fifa_code'],
                            'name': row['team_name']
                        }
            except Exception as e:
                print(f"Avertissement: Impossible de charger teams.csv pour simulation: {e}")

    updates = []
    
    for m in local_matches:
        kickoff = m['kickoff_utc']
        end_time = kickoff + datetime.timedelta(hours=2) # Un match dure environ 2 heures
        kickoff_utc_str = kickoff.strftime('%Y-%m-%dT%H:%M:%SZ')
        
        home_code = teams_map.get(m.get('home_team_id'), {}).get('code') or ''
        away_code = teams_map.get(m.get('away_team_id'), {}).get('code') or ''
        
        if sim_dt >= end_time:
            # Match terminé : score déterministe basé sur l'ID du match
            random.seed(m['id'])
            home_score = random.randint(0, 4)
            away_score = random.randint(0, 3)
            
            # Générer les évènements de match simulés
            sim_events = []
            if home_score > 0 or away_score > 0:
                sim_events = generate_mock_events(home_score, away_score, m['id'], 'Finished', 90, home_code or 'DOM', away_code or 'EXT')
            
            events_base64 = ""
            if sim_events:
                import base64
                events_json = json.dumps(sim_events)
                events_base64 = base64.b64encode(events_json.encode('utf-8')).decode('utf-8')
                
            updates.append({
                'id': m['id'],
                'status': 'Finished',
                'home_score': home_score,
                'away_score': away_score,
                'home_team_code': home_code,
                'away_team_code': away_code,
                'kickoff_utc': kickoff_utc_str,
                'events': events_base64
            })
        elif kickoff <= sim_dt < end_time:
            # Match en cours (Live) : score progressif changeant toutes les 5 minutes réelles
            elapsed_minutes = int((sim_dt - kickoff).total_seconds() / 60)
            elapsed_minutes_capped = min(90, max(1, elapsed_minutes))
            
            # Pour que le score change en temps réel, on ajoute le bloc de minutes réelles à la graine aléatoire
            now_minute_block = int(datetime.datetime.now().minute / 5)
            random.seed(m['id'] + now_minute_block)
            
            home_score = random.randint(0, int(elapsed_minutes / 30) + 1)
            away_score = random.randint(0, int(elapsed_minutes / 40) + 1)
            
            # Générer les évènements de match simulés
            sim_events = []
            if home_score > 0 or away_score > 0:
                sim_events = generate_mock_events(home_score, away_score, m['id'], 'Live', elapsed_minutes_capped, home_code or 'DOM', away_code or 'EXT')
            
            events_base64 = ""
            if sim_events:
                import base64
                events_json = json.dumps(sim_events)
                events_base64 = base64.b64encode(events_json.encode('utf-8')).decode('utf-8')
                
            updates.append({
                'id': m['id'],
                'status': 'Live',
                'home_score': home_score,
                'away_score': away_score,
                'home_team_code': home_code,
                'away_team_code': away_code,
                'kickoff_utc': kickoff_utc_str,
                'events': events_base64
            })
            
    return updates


def get_team_emoji(team_name, league_id):
    overrides = {
        "Real Madrid": "⚪️", "Barcelona": "🔵🔴", "Atletico Madrid": "🔴⚪️",
        "Juventus": "⚪️⚫️", "AC Milan": "🔴⚫️", "Inter": "🔵⚫️",
        "Bayern Munich": "🔴", "Borussia Dortmund": "🟡",
        "Paris Saint Germain": "🔵🔴", "Marseille": "🔵⚪️",
        "Manchester City": "🔵", "Manchester United": "🔴", "Liverpool": "🔴",
        "Arsenal": "🔴⚪️", "Chelsea": "🔵",
        "Flamengo": "🔴⚫️", "Palmeiras": "🟢", "Sao Paulo": "🔴⚪️⚫️"
    }
    if team_name in overrides:
        return overrides[team_name]
    
    country_flags = {
        140: "🇪🇸",
        135: "🇮🇹",
        78: "🇩🇪",
        2: "🇪🇺",
        39: "🦁",
        61: "🇫🇷",
        71: "🇧🇷"
    }
    return country_flags.get(league_id, "⚽️")

def get_mapped_events(api_events, home_team_id):
    mapped = []
    for ev in api_events:
        ev_type = ev.get('type')
        if not ev_type:
            continue
            
        detail = ev.get('detail') or ""
        t_type = ""
        if ev_type.lower() == 'goal':
            t_type = 'goal'
        elif ev_type.lower() == 'card':
            if 'yellow' in detail.lower():
                t_type = 'yellow_card'
            elif 'red' in detail.lower():
                t_type = 'red_card'
                
        if not t_type:
            continue
            
        minute = str(ev.get('time', {}).get('elapsed') or 0)
        extra = ev.get('time', {}).get('extra')
        if extra:
            minute = f"{minute}+{extra}"
        minute += "'"
        
        player_name = ev.get('player', {}).get('name') or "Joueur"
        team_id = ev.get('team', {}).get('id')
        team_side = 'home' if team_id == home_team_id else 'away'
        
        mapped.append({
            'minute': minute,
            'type': t_type,
            'player': player_name,
            'team': team_side
        })
    
    # Return as base64 encoded json string
    json_str = json.dumps(mapped)
    return base64.b64encode(json_str.encode('utf-8')).decode('utf-8')

def fetch_club_league_updates(api_key, league_id, season=2026):
    print(f"Fetching club league updates from API-Football for league {league_id}, season {season}...")
    url = f"https://v3.football.api-sports.io/fixtures?league={league_id}&season={season}"
    headers = {
        "x-apisports-key": api_key,
        "User-Agent": "Mozilla/5.0"
    }
    req = urllib.request.Request(url, headers=headers)
    
    try:
        with urllib.request.urlopen(req, timeout=15) as response:
            data = json.loads(response.read().decode('utf-8'))
    except Exception as e:
        print(f"Erreur lors de la requête API-Football : {e}")
        return None
        
    fixtures = data.get("response", [])
    print(f"Reçu {len(fixtures)} matchs de API-Football.")
    
    updates = []
    for f in fixtures:
        fixture_obj = f.get("fixture", {})
        status_obj = fixture_obj.get("status", {})
        status_short = status_obj.get("short") or ""
        
        # Map status
        if status_short in ["FT", "AET", "PEN"]:
            status = "Finished"
        elif status_short in ["1H", "HT", "2H", "ET", "BT", "P", "INT"]:
            status = "Live"
        else:
            status = "Scheduled"
            
        teams_obj = f.get("teams", {})
        home_team = teams_obj.get("home", {})
        away_team = teams_obj.get("away", {})
        
        home_id = str(home_team.get("id") or "")
        away_id = str(away_team.get("id") or "")
        
        goals_obj = f.get("goals", {})
        home_score = goals_obj.get("home")
        away_score = goals_obj.get("away")
        if home_score is None: home_score = 0
        if away_score is None: away_score = 0
        
        # Date conversion and shifting (+2 years to match 2026 simulation)
        kickoff_utc = fixture_obj.get("date")
        if kickoff_utc:
            kickoff_utc = kickoff_utc.replace("2024-", "2026-").replace("2025-", "2027-")
            
        # Dynamically set future matches (after virtual date July 2, 2026) as Scheduled
        if kickoff_utc and kickoff_utc > "2026-07-02T08:00:00":
            status = "Scheduled"
            home_score = 0
            away_score = 0
            events_base64 = ""
            # If the match was marked as finished in the raw API response but is in the future in 2026,
            # we want to ensure it is Scheduled so users can make predictions.
        
        # Mapped events
        events_list = f.get("events") or []
        events_base64 = get_mapped_events(events_list, home_team.get("id"))
        
        # Extra fields for on-the-fly client creation
        home_name = home_team.get("name") or "Home"
        home_emoji = get_team_emoji(home_name, league_id)
        away_name = away_team.get("name") or "Away"
        away_emoji = get_team_emoji(away_name, league_id)
        home_logo = home_team.get("logo") or ""
        away_logo = away_team.get("logo") or ""
        
        venue_obj = fixture_obj.get("venue", {})
        venue_name = venue_obj.get("name") or "Stade"
        venue_city = venue_obj.get("city") or "Ville"
        country_map = {
            140: "Espagne",
            135: "Italie",
            78: "Allemagne",
            2: "Europe",
            39: "Angleterre",
            61: "France",
            71: "Brésil"
        }
        venue_country = country_map.get(league_id, "International")
        
        league_obj = f.get("league", {})
        stage = league_obj.get("name") or "League"
        group_or_label = league_obj.get("round") or "Journée"
        
        # Unique match ID prefixed with league_id
        match_id = f"{league_id}_{fixture_obj.get('id')}"
        
        updates.append({
            "id": match_id,
            "status": status,
            "home_score": home_score,
            "away_score": away_score,
            "home_team_code": home_id,
            "away_team_code": away_id,
            "kickoff_utc": kickoff_utc,
            "events": events_base64,
            "home_team_name": home_name,
            "home_team_emoji": home_emoji,
            "away_team_name": away_name,
            "away_team_emoji": away_emoji,
            "stage": stage,
            "group_or_label": group_or_label,
            "venue_name": venue_name,
            "venue_city": venue_city,
            "venue_country": venue_country,
            "home_team_logo": home_logo,
            "away_team_logo": away_logo
        })
        
    return updates

def fetch_club_league_standings(api_key, league_id, season=2026):
    print(f"Fetching club league standings from API-Football for league {league_id}, season {season}...")
    url = f"https://v3.football.api-sports.io/standings?league={league_id}&season={season}"
    headers = {
        "x-apisports-key": api_key,
        "User-Agent": "Mozilla/5.0"
    }
    req = urllib.request.Request(url, headers=headers)
    
    try:
        with urllib.request.urlopen(req, timeout=15) as response:
            data = json.loads(response.read().decode('utf-8'))
    except Exception as e:
        print(f"Erreur lors de la requête API-Football standings : {e}")
        return []
        
    response_list = data.get("response", [])
    if not response_list:
        return []
        
    league_data = response_list[0].get("league", {})
    standings_groups = league_data.get("standings", [])
    if not standings_groups:
        return []
        
    api_standings = standings_groups[0]
    
    standings = []
    for s in api_standings:
        team_obj = s.get("team", {})
        team_name = team_obj.get("name") or "Team"
        team_id = str(team_obj.get("id") or "")
        
        all_stats = s.get("all", {})
        goals = all_stats.get("goals", {})
        
        standings.append({
            "group": {
                140: "La Liga",
                135: "Serie A",
                78: "Bundesliga",
                2: "Champions League",
                39: "Premier League",
                61: "Ligue 1",
                71: "Brasileirão Série A"
            }.get(league_id, "League"),
            "position": s.get("rank") or 0,
            "team_name": team_name,
            "fifa_code": team_id,
            "played": all_stats.get("played") or 0,
            "won": all_stats.get("win") or 0,
            "draw": all_stats.get("draw") or 0,
            "lost": all_stats.get("lose") or 0,
            "points": s.get("points") or 0,
            "goals_for": goals.get("for") or 0,
            "goals_against": goals.get("against") or 0,
            "goal_difference": s.get("goalsDiff") or 0
        })
        
    return standings


def write_updates_to_csv(updates, output_path):
    with open(output_path, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f)
        writer.writerow([
            'id', 'status', 'home_score', 'away_score', 'home_team_code', 'away_team_code', 'kickoff_utc', 'events',
            'home_team_name', 'home_team_emoji', 'away_team_name', 'away_team_emoji', 'stage', 'group_or_label',
            'venue_name', 'venue_city', 'venue_country', 'home_team_logo', 'away_team_logo'
        ])
        for u in updates:
            writer.writerow([
                u['id'],
                u['status'],
                u['home_score'],
                u['away_score'],
                u.get('home_team_code', ''),
                u.get('away_team_code', ''),
                u.get('kickoff_utc', ''),
                u.get('events', ''),
                u.get('home_team_name', ''),
                u.get('home_team_emoji', ''),
                u.get('away_team_name', ''),
                u.get('away_team_emoji', ''),
                u.get('stage', ''),
                u.get('group_or_label', ''),
                u.get('venue_name', ''),
                u.get('venue_city', ''),
                u.get('venue_country', ''),
                u.get('home_team_logo', ''),
                u.get('away_team_logo', '')
            ])
    print(f"Succès : {len(updates)} matchs écrits dans {output_path}")

def load_teams_metadata(teams_csv_path):
    teams_metadata = {}
    if not os.path.exists(teams_csv_path):
        print(f"Erreur : Fichier teams.csv introuvable à {teams_csv_path}")
        return teams_metadata
    with open(teams_csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            try:
                tid = int(row['id'])
                teams_metadata[tid] = {
                    'name': row['team_name'].strip(),
                    'code': row['fifa_code'].strip(),
                    'group': f"Group {row['group_letter'].strip()}"
                }
            except Exception as e:
                print(f"Erreur parsing team: {e}")
    return teams_metadata

def fetch_api_standings(api_key):
    print("Récupération des classements depuis l'API football-data.org...")
    url = "https://api.football-data.org/v4/competitions/WC/standings"
    req = urllib.request.Request(url)
    req.add_header("X-Auth-Token", api_key)
    
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode('utf-8'))
    except Exception as e:
        print(f"Erreur lors de la requête API classement : {e}")
        return None
        
    api_standings = data.get('standings', [])
    print(f"Reçu {len(api_standings)} groupes de classement de l'API.")
    
    rows = []
    for group_data in api_standings:
        group_raw = group_data.get('group', '')
        if not group_raw.startswith("Group ") and not group_raw.startswith("GROUP_"):
            continue
            
        if group_raw.startswith("Group "):
            group_name = group_raw
        else:
            group_letter = group_raw.split("_")[1]
            group_name = f"Group {group_letter}"
        
        table = group_data.get('table', [])
        for team_standing in table:
            tla = team_standing.get('team', {}).get('tla') or ''
            if tla == 'URY': tla = 'URU'
            name = team_standing.get('team', {}).get('name') or ''
            
            rows.append({
                'group': group_name,
                'position': team_standing.get('position'),
                'team_name': name,
                'fifa_code': tla,
                'played': team_standing.get('playedGames', 0),
                'won': team_standing.get('won', 0),
                'draw': team_standing.get('draw', 0),
                'lost': team_standing.get('lost', 0),
                'points': team_standing.get('points', 0),
                'goals_for': team_standing.get('goalsFor', 0),
                'goals_against': team_standing.get('goalsAgainst', 0),
                'goal_difference': team_standing.get('goalDifference', 0)
            })
            
    return rows

def calculate_standings(local_matches, updates, teams_metadata):
    scores = {}
    for u in updates:
        scores[u['id']] = u
        
    standings = {}
    for tid in teams_metadata:
        standings[tid] = {
            'played': 0,
            'won': 0,
            'draw': 0,
            'lost': 0,
            'points': 0,
            'goals_for': 0,
            'goals_against': 0,
            'goal_diff': 0
        }
        
    for m in local_matches:
        if not m['match_label'].startswith("Group"):
            continue
            
        m_id = m['id']
        update = scores.get(m_id)
        if not update or update['status'] == 'Scheduled':
            continue
            
        home_id = m['home_team_id']
        away_id = m['away_team_id']
        
        if not home_id or not away_id:
            continue
            
        home_score = int(update['home_score'])
        away_score = int(update['away_score'])
        
        standings[home_id]['played'] += 1
        standings[away_id]['played'] += 1
        standings[home_id]['goals_for'] += home_score
        standings[home_id]['goals_against'] += away_score
        standings[away_id]['goals_for'] += away_score
        standings[away_id]['goals_against'] += home_score
        
        if home_score > away_score:
            standings[home_id]['won'] += 1
            standings[home_id]['points'] += 3
            standings[away_id]['lost'] += 1
        elif home_score < away_score:
            standings[away_id]['won'] += 1
            standings[away_id]['points'] += 3
            standings[home_id]['lost'] += 1
        else:
            standings[home_id]['draw'] += 1
            standings[home_id]['points'] += 1
            standings[away_id]['draw'] += 1
            standings[away_id]['points'] += 1
            
    for tid in standings:
        standings[tid]['goal_diff'] = standings[tid]['goals_for'] - standings[tid]['goals_against']
        
    groups = {}
    for tid, meta in teams_metadata.items():
        gname = meta['group']
        if gname not in groups:
            groups[gname] = []
        groups[gname].append((tid, standings[tid]))
        
    for gname in groups:
        groups[gname].sort(key=lambda x: (
            -x[1]['points'],
            -x[1]['goal_diff'],
            -x[1]['goals_for'],
            teams_metadata[x[0]]['name']
        ))
        
    rows = []
    for gname in sorted(groups.keys()):
        for pos, (tid, stats) in enumerate(groups[gname], 1):
            meta = teams_metadata[tid]
            rows.append({
                'group': gname,
                'position': pos,
                'team_name': meta['name'],
                'fifa_code': meta['code'],
                'played': stats['played'],
                'won': stats['won'],
                'draw': stats['draw'],
                'lost': stats['lost'],
                'points': stats['points'],
                'goals_for': stats['goals_for'],
                'goals_against': stats['goals_against'],
                'goal_difference': stats['goal_diff']
            })
            
    return rows

def write_standings_to_csv(standings, output_path):
    with open(output_path, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f)
        writer.writerow([
            'group', 'position', 'team_name', 'fifa_code', 
            'played', 'won', 'draw', 'lost', 'points', 
            'goals_for', 'goals_against', 'goal_difference'
        ])
        for s in standings:
            writer.writerow([
                s['group'],
                s['position'],
                s['team_name'],
                s['fifa_code'],
                s['played'],
                s['won'],
                s['draw'],
                s['lost'],
                s['points'],
                s['goals_for'],
                s['goals_against'],
                s['goal_difference']
            ])
    print(f"Succès : Classements écrits dans {output_path}")

def commit_and_push(base_dir):
    if not os.path.exists(os.path.join(base_dir, '.git')):
        print("Dossier non Git. Commit/Push ignoré.")
        return
        
    try:
        subprocess.run(["git", "config", "--global", "user.name", "GitHub Actions Bot"], check=True)
        subprocess.run(["git", "config", "--global", "user.email", "actions@github.com"], check=True)
        files_to_add = []
        for f in os.listdir(base_dir):
            if f.endswith('update.csv') or f.endswith('standings.csv') or f == 'matches_update.csv':
                files_to_add.append(f)
        for f in files_to_add:
            subprocess.run(["git", "add", os.path.join(base_dir, f)], check=True)
        
        res = subprocess.run(["git", "diff", "--quiet"]) # check if modified
        res2 = subprocess.run(["git", "diff", "--cached", "--quiet"])
        if res.returncode != 0 or res2.returncode != 0:
            for f in files_to_add:
                subprocess.run(["git", "add", os.path.join(base_dir, f)], check=True)
            subprocess.run(["git", "commit", "-m", "Auto-update matches scores and standings [skip ci]"], check=True)
            subprocess.run(["git", "push"], check=True)
            print("Scores et classements committés et pushés avec succès sur GitHub.")
        else:
            print("Aucune modification à committer.")
    except Exception as e:
        print(f"Erreur lors du commit/push Git : {e}")

# --- APNS & Firestore Push Functions ---

def init_firebase():
    if firebase_admin is None:
        return None
        
    try:
        return firestore.client()
    except ValueError:
        pass
        
    service_account_env = os.environ.get("FIREBASE_SERVICE_ACCOUNT")
    if service_account_env:
        try:
            service_account_info = json.loads(service_account_env)
            cred = credentials.Certificate(service_account_info)
            firebase_admin.initialize_app(cred)
            return firestore.client()
        except Exception as e:
            print(f"Erreur d'initialisation Firebase depuis l'environnement : {e}")
    else:
        local_key_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "serviceAccountKey.json")
        if os.path.exists(local_key_path):
            try:
                cred = credentials.Certificate(local_key_path)
                firebase_admin.initialize_app(cred)
                return firestore.client()
            except Exception as e:
                print(f"Erreur d'initialisation Firebase depuis serviceAccountKey.json : {e}")
    return None

def generate_apns_token(key_id, team_id, private_key_pem):
    if jwt is None:
        return None
    headers = {
        "alg": "ES256",
        "kid": key_id
    }
    payload = {
        "iss": team_id,
        "iat": int(time.time())
    }
    token = jwt.encode(payload, private_key_pem, algorithm="ES256", headers=headers)
    if isinstance(token, bytes):
        token = token.decode("ascii")
    return token

def send_apns_push(token, device_token, bundle_id, payload):
    if httpx is None:
        return False
        
    use_sandbox = os.environ.get("APNS_SANDBOX", "false").lower() == "true"
    host = "api.sandbox.push.apple.com" if use_sandbox else "api.push.apple.com"
    url = f"https://{host}/3/device/{device_token}"
    
    headers = {
        "apns-topic": bundle_id,
        "apns-push-type": "liveactivity",
        "apns-expiration": "0",
        "apns-priority": "10",
        "authorization": f"bearer {token}"
    }
    
    print(f"APNs Request -> URL: {url} | Topic: {headers['apns-topic']}")
    try:
        with httpx.Client(http2=True) as client:
            response = client.post(url, json=payload, headers=headers)
            if response.status_code == 200:
                print(f"Push envoyé avec succès au token {device_token[:8]}...")
                return True
            else:
                print(f"Erreur APNs : Status {response.status_code}, Réponse : {response.text}")
                return False
    except Exception as e:
        print(f"Erreur HTTP/2 client APNs pour {device_token[:8]} : {e}")
        return False

def load_previous_scores(output_path):
    previous = {}
    if os.path.exists(output_path):
        try:
            with open(output_path, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    try:
                        previous[int(row['id'])] = {
                            'status': row['status'],
                            'home_score': int(row['home_score']),
                            'away_score': int(row['away_score'])
                        }
                    except:
                        pass
        except Exception as e:
            print(f"Erreur lors du chargement des scores précédents : {e}")
    return previous

def flag_emoji(code):
    mappings = {
        "MEX": "🇲🇽", "RSA": "🇿🇦", "KOR": "🇰🇷", "CAN": "🇨🇦",
        "QAT": "🇶🇦", "SUI": "🇨🇭", "BRA": "🇧🇷", "MAR": "🇲🇦",
        "HAI": "🇭🇹", "SCO": "🏴󠁧󠁢󠁳󠁣󠁴󠁿", "USA": "🇺🇸", "PAR": "🇵🇾",
        "AUS": "🇦🇺", "GER": "🇩🇪", "CUR": "🇨🇼", "CIV": "🇨🇮",
        "ECU": "🇪🇨", "NED": "🇳🇱", "JPN": "🇯🇵", "TUN": "🇹🇳",
        "BEL": "🇧🇪", "EGY": "🇪🇬", "IRN": "🇮🇷", "NZL": "🇳🇿",
        "ESP": "🇪🇸", "CPV": "🇨🇻", "KSA": "🇸🇦", "URU": "🇺🇾",
        "FRA": "🇫🇷", "SEN": "🇸🇳", "NOR": "🇳🇴", "ARG": "🇦🇷",
        "ALG": "🇩🇿", "AUT": "🇦🇹", "JOR": "🇯🇴", "POR": "🇵🇹",
        "UZB": "🇺🇿", "COL": "🇨🇴", "ENG": "🏴󠁧󠁢󠁥󠁮󠁧󠁿", "CRO": "🇭🇷",
        "GHA": "🇬🇭", "PAN": "🇵🇦",
        "BIH": "🇧🇦", "SWE": "🇸🇪", "TUR": "🇹🇷", "CZE": "🇨🇿",
        "COD": "🇨🇩", "IRQ": "🇮🇶"
    }
    return mappings.get(code, "🏳️")

def send_apns_for_updates(changed_matches, local_matches, teams_metadata, previous_scores):
    db = init_firebase()
    if db is None:
        print("Firebase non initialisé. Impossible de récupérer les tokens push.")
        return
        
    key_id = os.environ.get("APNS_KEY_ID", "").strip()
    team_id = os.environ.get("APNS_TEAM_ID", "").strip()
    private_key_pem = os.environ.get("APNS_PRIVATE_KEY", "").strip()
    bundle_id = (os.environ.get("APNS_BUNDLE_ID") or "com.mm.WorldCup2026").strip()
    
    if not (key_id and team_id and private_key_pem):
        print("Identifiants APNs non configurés dans l'environnement. Envoi des pushs annulé.")
        return
        
    private_key_pem = private_key_pem.replace("\\n", "\n")
    
    try:
        apns_token = generate_apns_token(key_id, team_id, private_key_pem)
    except Exception as e:
        print(f"Erreur lors de la génération du token JWT APNs : {e}")
        return
        
    for u in changed_matches:
        match_id = str(u['id'])
        status = u['status']
        home_score = u['home_score']
        away_score = u['away_score']
        
        if status not in ['Live', 'Finished']:
            continue
            
        prev = previous_scores.get(u['id'])
        # Envoyer le push de démarrage dès que le match est Live (permet aux nouveaux appareils de démarrer l'activité en cours de route)
        is_new_live = status == 'Live' and (not prev or prev.get('status') != 'Live')
        
        # 1. ENVOI DU PUSH DE DÉMARRAGE ("start") AU TOUT DEBUT DU MATCH (PUSH TO START)
        if is_new_live:
            print(f"Match {match_id} commence (Live) ! Envoi des pushs de démarrage APNs (Push to Start)...")
            try:
                local_m = next((m for m in local_matches if m['id'] == u['id']), None)
                if local_m:
                    home_code = u.get('home_team_code') or ''
                    away_code = u.get('away_team_code') or ''
                    
                    home_name = teams_metadata.get(local_m.get('home_team_id', 0), {}).get('name') or home_code or "TBD"
                    away_name = teams_metadata.get(local_m.get('away_team_id', 0), {}).get('name') or away_code or "TBD"
                    stage = local_m.get('match_label', 'Knockout')
                    
                    # Récupérer les tokens de démarrage des appareils
                    start_tokens_ref = db.collection("device_start_tokens")
                    start_docs = start_tokens_ref.stream()
                    
                    start_targets = []
                    for doc in start_docs:
                        data = doc.to_dict()
                        token = data.get("pushToStartToken")
                        fav_team = data.get("favoriteTeamId") or ""
                        t_bundle_id = data.get("bundleId") or bundle_id
                        
                        # Cible : tous les appareils enregistrés pour tous les matchs en direct
                        if token:
                            start_targets.append((token, t_bundle_id))
                                
                    if start_targets:
                        print(f"{len(start_targets)} appareil(s) éligible(s) pour le Push to Start du match {match_id}.")
                        
                        start_payload = {
                            "aps": {
                                "timestamp": int(time.time()),
                                "event": "start",
                                "content-state": {
                                    "homeScore": int(home_score),
                                    "awayScore": int(away_score),
                                    "status": "0'",
                                    "matchStatusRawValue": status,
                                    "liveLabel": "LIVE",
                                    "timerStartDate": time.time()
                                },
                                "attributes-type": "LiveScoreAttributes",
                                "attributes": {
                                    "matchId": match_id,
                                    "homeTeamName": home_name,
                                    "homeTeamEmoji": flag_emoji(home_code),
                                    "awayTeamName": away_name,
                                    "awayTeamEmoji": flag_emoji(away_code),
                                    "stage": stage
                                },
                                "alert": {
                                    "title": "Match en Direct",
                                    "body": f"Le match {home_name} vs {away_name} a commencé !"
                                }
                            }
                        }
                        
                        for t, t_bundle_id in start_targets:
                            # Assurer que le topic ne contient pas de doublon de suffixe
                            topic = t_bundle_id
                            if not topic.endswith(".push-type.liveactivity"):
                                topic = f"{topic}.push-type.liveactivity"
                            send_apns_push(apns_token, t, topic, start_payload)
                    else:
                        print(f"Aucun appareil abonné (Push to Start) pour le match {match_id}.")
            except Exception as ex:
                print(f"Erreur d'envoi du Push to Start pour le match {match_id} : {ex}")
        
        # 2. ENVOI DES MISES A JOUR CLASSIQUES ("update")
        print(f"Recherche de tokens Live Activity actifs pour le match {match_id} ({status})...")
        try:
            activities_ref = db.collection("live_activities")
            query = activities_ref.where("matchId", "==", match_id)
            docs = query.stream()
            
            activity_targets = []
            for doc in docs:
                data = doc.to_dict()
                token = data.get("pushToken")
                t_bundle_id = data.get("bundleId") or bundle_id
                if token:
                    activity_targets.append((token, t_bundle_id))
                    
            if not activity_targets:
                print(f"Aucun token Live Activity actif trouvé pour le match {match_id}.")
                continue
                
            print(f"{len(activity_targets)} token(s) actif(s) trouvé(s). Envoi de la mise à jour APNs...")
            
            status_text = "Live"
            timer_start_date = None
            
            if u.get('kickoff_utc'):
                try:
                    utc_str = u['kickoff_utc']
                    if utc_str.endswith('Z'):
                        utc_str = utc_str[:-1] + '+00:00'
                    dt = datetime.datetime.fromisoformat(utc_str)
                    timer_start_date = dt.timestamp()
                except Exception as e:
                    print(f"Erreur lors du parsing de la date de coup d'envoi pour le chrono : {e}")
                    
            if status == "Live":
                api_match_time = u.get('match_time')
                if api_match_time:
                    if any(x in api_match_time.upper() for x in ["HT", "MT", "HALF", "TEMP"]):
                        elapsed = 45
                        status_text = "HT"
                        timer_start_date = None
                    elif any(x in api_match_time.upper() for x in ["FIN", "END"]):
                        elapsed = 90
                        status_text = "Finished"
                        timer_start_date = None
                    else:
                        digits = re.findall(r'\d+', api_match_time)
                        if digits:
                            elapsed = int(digits[0])
                            if "45" in api_match_time and "+" in api_match_time:
                                elapsed = 45
                            status_text = f"{elapsed}'"
                            
                            if u.get('kickoff_utc'):
                                try:
                                    utc_str = u['kickoff_utc']
                                    if utc_str.endswith('Z'):
                                        utc_str = utc_str[:-1] + '+00:00'
                                    kickoff_ts = datetime.datetime.fromisoformat(utc_str).timestamp()
                                    if elapsed <= 45:
                                        timer_start_date = kickoff_ts
                                    else:
                                        timer_start_date = kickoff_ts + 60 * 60
                                except Exception as e:
                                    print(f"Erreur parsing kickoff_utc dans match_time: {e}")
                                    timer_start_date = None
                        else:
                            elapsed = 0
                            status_text = "Live"
                            if u.get('kickoff_utc'):
                                try:
                                    utc_str = u['kickoff_utc']
                                    if utc_str.endswith('Z'):
                                        utc_str = utc_str[:-1] + '+00:00'
                                    timer_start_date = datetime.datetime.fromisoformat(utc_str).timestamp()
                                except:
                                    timer_start_date = None
                else:
                    if timer_start_date:
                        elapsed = max(0, int((time.time() - timer_start_date) / 60))
                        if elapsed <= 45:
                            status_text = f"{elapsed}'"
                        elif elapsed <= 60:
                            status_text = "HT"
                            timer_start_date = None
                        elif elapsed <= 105:
                            status_text = f"{elapsed - 15}'"
                            timer_start_date = time.time() - (elapsed - 15) * 60
                        else:
                            status_text = "90'"
                            timer_start_date = time.time() - 90 * 60
                    else:
                        status_text = "Live"
            else:
                status_text = "Finished"
                timer_start_date = None
                
            payload = {
                "aps": {
                    "timestamp": int(time.time()),
                    "event": "update" if status == "Live" else "end",
                    "content-state": {
                        "homeScore": int(home_score),
                        "awayScore": int(away_score),
                        "status": status_text,
                        "matchStatusRawValue": status,
                        "liveLabel": "LIVE" if status == "Live" else "FINISHED",
                        "timerStartDate": timer_start_date if timer_start_date is not None else None
                    }
                }
            }
            
            for t, t_bundle_id in activity_targets:
                # Assurer que le topic ne contient pas de doublon de suffixe
                topic = t_bundle_id
                if not topic.endswith(".push-type.liveactivity"):
                    topic = f"{topic}.push-type.liveactivity"
                send_apns_push(apns_token, t, topic, payload)
                
        except Exception as e:
            print(f"Erreur lors du traitement des pushs pour le match {match_id} : {e}")

# --- End APNS & Firestore Push Functions ---

def run_single_iteration(args, local_matches, teams, teams_metadata, output_path, standings_path, base_dir):
    updates = []
    standings = []
    
    # Charger les scores précédents pour détecter les changements
    previous_scores = load_previous_scores(output_path)
    
    league = getattr(args, "league", "WC2026")
    
    # 1. Obtenir les scores de match et standings selon la ligue
    if league == "WC2026":
        if args.simulate:
            updates = run_simulation(args.sim_date, local_matches, base_dir)
        else:
            api_key = args.api_key or os.environ.get("FOOTBALL_DATA_API_KEY") or ""
            fetched = fetch_api_updates(api_key, local_matches, teams)
            if fetched is not None:
                updates = fetched
            else:
                print("Erreur de récupération API.")
                return False
        standings = calculate_standings(local_matches, updates, teams_metadata)
    else:
        # Configuration club leagues
        configs = {
            "LALIGA": 140,
            "SERIEA": 135,
            "BUNDESLIGA": 78,
            "CL": 2,
            "PL": 39,
            "L1": 61,
            "BSA": 71
        }
        league_id = configs.get(league)
        api_key = args.api_key or os.environ.get("FOOTBALL_API_KEY") or os.environ.get("FOOTBALL_DATA_API_KEY") or ""
        if not api_key:
            print("Attention : FOOTBALL_API_KEY non fournie. Utilisation d'un mock vide.")
            updates = []
            standings = []
        else:
            fetched_updates = fetch_club_league_updates(api_key, league_id, season=2024)
            if fetched_updates is not None:
                updates = fetched_updates
            else:
                print("Erreur API-Football updates.")
                return False
                
            fetched_standings = fetch_club_league_standings(api_key, league_id, season=2024)
            standings = fetched_standings
            
    # Détecter les changements
    changed_matches = []
    for u in updates:
        match_id = u['id']
        prev = previous_scores.get(match_id)
        if (not prev or 
            prev['status'] != u['status'] or 
            prev['home_score'] != u['home_score'] or 
            prev['away_score'] != u['away_score'] or
            u['status'] == 'Live'):
            changed_matches.append(u)
            
    write_updates_to_csv(updates, output_path)
    write_standings_to_csv(standings, standings_path)
    
    # Envoyer les notifications push APNs pour les matchs modifiés
    if changed_matches:
        send_apns_for_updates(changed_matches, local_matches, teams_metadata, previous_scores)
        
    commit_and_push(base_dir)
    return any(u['status'] == 'Live' for u in updates)

def main():
    parser = argparse.ArgumentParser(description="Script de mise à jour des scores pour la Coupe du Monde 2026")
    parser.add_argument('--api-key', type=str, default=None, help="Clé d'API football-data.org (optionnel)")
    parser.add_argument('--simulate', action='store_true', help="Activer le mode de simulation")
    parser.add_argument('--sim-date', type=str, default=None, help="Date virtuelle de simulation (Ex: 2026-06-15)")
    parser.add_argument('--live-loop', action='store_true', help="Activer la boucle haute fréquence d'une minute en cas de match en cours")
    parser.add_argument('--league', type=str, default="WC2026", help="Ligue à mettre à jour (WC2026, LALIGA, SERIEA, BUNDESLIGA)")
    
    args = parser.parse_args()
    
    base_dir = os.path.dirname(os.path.abspath(__file__))
    teams_path = os.path.join(base_dir, 'teams.csv')
    matches_path = os.path.join(base_dir, 'matches.csv')
    
    # Adapt output paths dynamically based on selected league
    prefix_map = {
        "WC2026": "",
        "LALIGA": "laliga_",
        "SERIEA": "seriea_",
        "BUNDESLIGA": "bundesliga_",
        "CL": "cl_",
        "PL": "pl_",
        "L1": "l1_",
        "BSA": "bsa_"
    }
    prefix = prefix_map.get(args.league, "")
    
    output_path = os.path.join(base_dir, f'{prefix}matches_update.csv' if args.league == "WC2026" else f'{prefix}update.csv')
    standings_path = os.path.join(base_dir, f'{prefix}standings.csv')
    
    teams = load_teams(teams_path)
    teams_metadata = load_teams_metadata(teams_path)
    local_matches = load_matches(matches_path)
    
    if not teams or not local_matches:
        print("Erreur : Données locales manquantes.")
        return
        
    if args.live_loop:
        print("Mode boucle haute fréquence activé. Vérification initiale...")
        is_live = run_single_iteration(args, local_matches, teams, teams_metadata, output_path, standings_path, base_dir)
        
        if is_live:
            print("Match en cours détecté ! Lancement de la boucle de 5 minutes (mise à jour toutes les 60 secondes).")
            # Comme la première itération a déjà tourné, on boucle 4 fois de plus avec un délai de 60 secondes
            for i in range(4):
                print(f"Attente de 60 secondes avant l'itération {i+2}/5...")
                time.sleep(60)
                run_single_iteration(args, local_matches, teams, teams_metadata, output_path, standings_path, base_dir)
        else:
            print("Aucun match en cours. Fin de la tâche unique.")
    else:
        run_single_iteration(args, local_matches, teams, teams_metadata, output_path, standings_path, base_dir)

if __name__ == '__main__':
    main()
