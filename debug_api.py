import os
import urllib.request
import json

def test_league(api_key, league_id, season):
    url = f"https://v3.football.api-sports.io/fixtures?league={league_id}&season={season}"
    req = urllib.request.Request(url, headers={"x-apisports-key": api_key, "User-Agent": "Mozilla/5.0"})
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            errors = data.get("errors")
            results = data.get("results", 0)
            print(f"League {league_id} Season {season}: errors={errors}, results_count={results}")
            if results > 0:
                fixtures = data.get("response", [])
                print(f"First fixture details: {fixtures[0].get('fixture', {}).get('id')} - {fixtures[0].get('teams', {}).get('home', {}).get('name')} vs {fixtures[0].get('teams', {}).get('away', {}).get('name')}")
    except Exception as e:
        print(f"Failed {league_id}: {e}")

def main():
    api_key = os.environ.get("FOOTBALL_API_KEY") or os.environ.get("FOOTBALL_DATA_API_KEY") or ""
    print("API Key length:", len(api_key))
    if not api_key:
        print("No API Key found.")
        return
    # Test different leagues and seasons
    test_league(api_key, 135, 2025)
    test_league(api_key, 135, 2026)
    test_league(api_key, 71, 2026)
    test_league(api_key, 140, 2025)
    test_league(api_key, 140, 2026)

if __name__ == '__main__':
    main()
