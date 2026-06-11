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

# Clé API par défaut (fournie par l'utilisateur)
DEFAULT_API_KEY = "1218b63c64c442a7bc766cf9f802c090"
API_URL = "https://api.football-data.org/v4/competitions/WC/matches"

def parse_kickoff_time(kickoff_str):
    # Exemple: "2026-06-11 15:00:00-06" -> ISO format
    iso_str = kickoff_str.replace(" ", "T")
    if len(iso_str) == 22: # Si le fuseau horaire est comme -06 au lieu de -06:00
        iso_str += ":00"
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

def find_local_match(api_match, local_matches, teams):
    home_tla = api_match.get('homeTeam', {}).get('tla')
    away_tla = api_match.get('awayTeam', {}).get('tla')
    
    api_home_id = teams.get(home_tla) if home_tla else None
    api_away_id = teams.get(away_tla) if away_tla else None
    
    api_date_str = api_match['utcDate']
    # Normalisation du fuseau horaire Z -> +00:00
    if api_date_str.endswith('Z'):
        api_date_str = api_date_str[:-1] + '+00:00'
    api_dt = datetime.datetime.fromisoformat(api_date_str).astimezone(datetime.timezone.utc)
    
    # 1. Recherche par correspondance exacte des deux équipes (idéal pour la phase de groupes)
    if api_home_id and api_away_id:
        for m in local_matches:
            if m['home_team_id'] == api_home_id and m['away_team_id'] == api_away_id:
                return m
                
    # 2. Recherche par heure de coup d'envoi (tolérance d'une heure) - Utile pour les phases éliminatoires (knockouts)
    candidates = []
    for m in local_matches:
        diff_seconds = abs((m['kickoff_utc'] - api_dt).total_seconds())
        if diff_seconds <= 3600:  # 1 heure
            candidates.append(m)
            
    if len(candidates) == 1:
        return candidates[0]
    elif len(candidates) > 1:
        # S'il y a plusieurs matchs en même temps, on filtre avec une des équipes
        for m in candidates:
            if m['home_team_id'] == api_home_id or m['away_team_id'] == api_away_id:
                return m
        return candidates[0]
        
    return None

def fetch_api_updates(api_key, local_matches, teams):
    print("Connexion à l'API football-data.org...")
    req = urllib.request.Request(API_URL)
    req.add_header("X-Auth-Token", api_key)
    
    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
    except Exception as e:
        print(f"Erreur lors de la requête API : {e}")
        return None
        
    api_matches = data.get('matches', [])
    print(f"Reçu {len(api_matches)} matchs de l'API.")
    
    updates = []
    matched_count = 0
    
    for api_m in api_matches:
        status_raw = api_m.get('status')
        
        # Mappage des statuts
        if status_raw in ['FINISHED', 'AWARDED']:
            status = 'Finished'
        elif status_raw in ['IN_PLAY', 'PAUSED']:
            status = 'Live'
        else:
            status = 'Scheduled'
            
        local_m = find_local_match(api_m, local_matches, teams)
        if local_m:
            score_obj = api_m.get('score', {})
            full_time = score_obj.get('fullTime', {})
            home_score = full_time.get('home')
            away_score = full_time.get('away')
            
            if home_score is None: home_score = 0
            if away_score is None: away_score = 0
            
            home_team_code = api_m.get('homeTeam', {}).get('tla') or ''
            away_team_code = api_m.get('awayTeam', {}).get('tla') or ''
            
            updates.append({
                'id': local_m['id'],
                'status': status,
                'home_score': home_score,
                'away_score': away_score,
                'home_team_code': home_team_code,
                'away_team_code': away_team_code
            })
            matched_count += 1
        else:
            h_name = api_m.get('homeTeam', {}).get('name')
            a_name = api_m.get('awayTeam', {}).get('name')
            print(f"Avertissement : Impossible de mapper le match de l'API {h_name} vs {a_name} ({api_m.get('utcDate')})")
            
    print(f"Mappage terminé : {matched_count} matchs mappés sur les matches locaux.")
    return updates

def run_simulation(sim_date_str, local_matches):
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
            
    updates = []
    
    for m in local_matches:
        kickoff = m['kickoff_utc']
        end_time = kickoff + datetime.timedelta(hours=2) # Un match dure environ 2 heures
        
        if sim_dt >= end_time:
            # Match terminé : score déterministe basé sur l'ID du match
            random.seed(m['id'])
            home_score = random.randint(0, 4)
            away_score = random.randint(0, 3)
            updates.append({
                'id': m['id'],
                'status': 'Finished',
                'home_score': home_score,
                'away_score': away_score,
                'home_team_code': '',
                'away_team_code': ''
            })
        elif kickoff <= sim_dt < end_time:
            # Match en cours (Live) : score progressif changeant toutes les 5 minutes réelles
            elapsed_minutes = int((sim_dt - kickoff).total_seconds() / 60)
            
            # Pour que le score change en temps réel, on ajoute le bloc de minutes réelles à la graine aléatoire
            now_minute_block = int(datetime.datetime.now().minute / 5)
            random.seed(m['id'] + now_minute_block)
            
            home_score = random.randint(0, int(elapsed_minutes / 30) + 1)
            away_score = random.randint(0, int(elapsed_minutes / 40) + 1)
            
            updates.append({
                'id': m['id'],
                'status': 'Live',
                'home_score': home_score,
                'away_score': away_score,
                'home_team_code': '',
                'away_team_code': ''
            })
            
    return updates

def write_updates_to_csv(updates, output_path):
    with open(output_path, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['id', 'status', 'home_score', 'away_score', 'home_team_code', 'away_team_code'])
        for u in updates:
            writer.writerow([
                u['id'],
                u['status'],
                u['home_score'],
                u['away_score'],
                u.get('home_team_code', ''),
                u.get('away_team_code', '')
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
        with urllib.request.urlopen(req) as response:
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
        
        subprocess.run(["git", "add", "matches_update.csv", "standings.csv"], check=True)
        
        res = subprocess.run(["git", "diff", "--quiet"]) # check if modified
        res2 = subprocess.run(["git", "diff", "--cached", "--quiet"])
        if res.returncode != 0 or res2.returncode != 0:
            # Stage again to be safe
            subprocess.run(["git", "add", "matches_update.csv", "standings.csv"], check=True)
            subprocess.run(["git", "commit", "-m", "Auto-update matches scores and standings [skip ci]"], check=True)
            subprocess.run(["git", "push"], check=True)
            print("Scores et classements committés et pushés avec succès sur GitHub.")
        else:
            print("Aucune modification à committer.")
    except Exception as e:
        print(f"Erreur lors du commit/push Git : {e}")

def run_single_iteration(args, local_matches, teams, teams_metadata, output_path, standings_path, base_dir):
    updates = []
    standings = []
    
    # 1. Obtenir les scores de match
    if args.simulate:
        updates = run_simulation(args.sim_date, local_matches)
    else:
        api_key = args.api_key or os.environ.get("FOOTBALL_DATA_API_KEY") or DEFAULT_API_KEY
        if not api_key:
            print("Erreur : Clé d'API non configurée.")
            return False
        fetched = fetch_api_updates(api_key, local_matches, teams)
        if fetched is not None:
            updates = fetched
        else:
            print("Erreur de récupération API.")
            return False
            
    # 2. Obtenir les classements
    if args.simulate:
        standings = calculate_standings(local_matches, updates, teams_metadata)
    else:
        api_key = args.api_key or os.environ.get("FOOTBALL_DATA_API_KEY") or DEFAULT_API_KEY
        fetched_standings = fetch_api_standings(api_key) if api_key else None
        if fetched_standings is not None:
            standings = fetched_standings
        else:
            print("Utilisation du calcul local pour le classement (de secours).")
            standings = calculate_standings(local_matches, updates, teams_metadata)
            
    write_updates_to_csv(updates, output_path)
    write_standings_to_csv(standings, standings_path)
    commit_and_push(base_dir)
    return any(u['status'] == 'Live' for u in updates)

def main():
    parser = argparse.ArgumentParser(description="Script de mise à jour des scores pour la Coupe du Monde 2026")
    parser.add_argument('--api-key', type=str, default=None, help="Clé d'API football-data.org (optionnel)")
    parser.add_argument('--simulate', action='store_true', help="Activer le mode de simulation")
    parser.add_argument('--sim-date', type=str, default=None, help="Date virtuelle de simulation (Ex: 2026-06-15)")
    parser.add_argument('--live-loop', action='store_true', help="Activer la boucle haute fréquence d'une minute en cas de match en cours")
    
    args = parser.parse_args()
    
    base_dir = os.path.dirname(os.path.abspath(__file__))
    teams_path = os.path.join(base_dir, 'teams.csv')
    matches_path = os.path.join(base_dir, 'matches.csv')
    output_path = os.path.join(base_dir, 'matches_update.csv')
    standings_path = os.path.join(base_dir, 'standings.csv')
    
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
