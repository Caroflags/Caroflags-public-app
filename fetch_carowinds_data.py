
import requests
import json

overpass_url = "http://overpass-api.de/api/interpreter"
overpass_query = """
[out:json];
(
  nwr["amenity"="toilets"](35.095,-80.950,35.110,-80.930);
  nwr["amenity"="fast_food"](35.095,-80.950,35.110,-80.930);
  nwr["amenity"="restaurant"](35.095,-80.950,35.110,-80.930);
  nwr["shop"](35.095,-80.950,35.110,-80.930);
);
out center;
"""

try:
    response = requests.get(overpass_url, params={'data': overpass_query})
    data = response.json()
except Exception as e:
    print(f"Error fetching data: {e}")
    try:
        print(response.text[:500])
    except:
        pass
    exit(1)

restrooms = []
restaurants = []
shops = []

for element in data.get('elements', []):
    tags = element.get('tags', {})
    
    # Get coordinates
    lat = element.get('lat')
    lon = element.get('lon')
    
    if lat is None or lon is None:
        if 'center' in element:
            lat = element['center']['lat']
            lon = element['center']['lon']
        else:
            continue

    if lat < 35.099:
        continue

    name = tags.get('name', 'Food Stand') # Default for restaurants
    
    if tags.get('amenity') == 'toilets':
        restrooms.append({'name': 'Restroom', 'lat': lat, 'lng': lon})
    elif tags.get('amenity') in ['fast_food', 'restaurant']:
         restaurants.append({'name': name, 'lat': lat, 'lng': lon})
    elif 'shop' in tags:
        shop_name = tags.get('name', 'Shop')
        shops.append({'name': shop_name, 'lat': lat, 'lng': lon})

print("List<Map<String, dynamic>> restrooms = [")
for r in restrooms:
    print(f"  {{'name': '{r['name']}', 'lat': {r['lat']}, 'lng': {r['lng']}}},")
print("];")

print("\nList<Map<String, dynamic>> restaurants = [")
for r in restaurants:
    print(f"  {{'name': '{r['name']}', 'lat': {r['lat']}, 'lng': {r['lng']}}},")
print("];")

print("\nList<Map<String, dynamic>> shops = [")
for s in shops:
    print(f"  {{'name': '{s['name']}', 'lat': {s['lat']}, 'lng': {s['lng']}}},")
print("];")
