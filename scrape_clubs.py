#!/usr/bin/env python3
"""
Web scraper to extract Cal Poly Construction Management club information
from https://construction.calpoly.edu/content/current/student-clubs
"""

import re
import requests
from bs4 import BeautifulSoup
import json
import firebase_admin
from firebase_admin import credentials, firestore

def scrape_cal_poly_clubs():
    """
    Scrape club information from Cal Poly CM website
    Returns a list of club dictionaries with: name, acronym, description, email
    """
    url = "https://construction.calpoly.edu/content/current/student-clubs"
    
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
    except requests.RequestException as e:
        print(f"Error fetching webpage: {e}")
        return []
    
    soup = BeautifulSoup(response.content, 'html.parser')
    clubs = []
    
    # Find all h3 tags that represent club names
    club_headers = soup.find_all('h3')
    
    for header in club_headers:
        club_name = header.get_text(strip=True)
        
        # Skip non-club headers
        if not club_name or club_name in ['2025-2026 Officers', 'ASCM  General Information', 
                                           'Advisors', 'CAED Representative', 'Advisor']:
            continue
        
        # Extract acronym from club name if present in parentheses
        acronym_match = re.search(r'\(([A-Z]+)\)', club_name)
        acronym = acronym_match.group(1) if acronym_match else ''
        
        # Clean club name (remove acronym in parentheses)
        clean_name = re.sub(r'\s*\([A-Z]+\)\s*$', '', club_name).strip()
        
        # Find the description paragraph (usually the first <p> after the header)
        description = ''
        current = header.find_next_sibling()
        while current:
            if current.name == 'p':
                desc_text = current.get_text(strip=True)
                # Skip officer/advisor info paragraphs
                if desc_text and not desc_text.startswith('President:') and \
                   not desc_text.startswith('Advisor'):
                    description = desc_text
                    break
            elif current.name in ['h3', 'h4']:
                # Stop if we hit another header
                if current.name == 'h3':
                    break
            current = current.find_next_sibling()
        
        # Find the general email (not officer-specific emails)
        email = ''
        # Look for email links in the section
        section = header.find_next('h4', string=re.compile(r'General Information|Advisor', re.IGNORECASE))
        if section:
            email_link = section.find_next('a', href=re.compile(r'^mailto:'))
            if email_link:
                email = email_link.get('href').replace('mailto:', '').strip()
        
        # If no general info section, look for club-specific email patterns
        if not email:
            # Look for "Email [Club Name]" pattern
            email_pattern = header.find_next('a', string=re.compile(r'^Email', re.IGNORECASE))
            if email_pattern:
                email = email_pattern.get('href', '').replace('mailto:', '').strip()
        
        # Only add clubs with meaningful data
        if clean_name and description:
            club_data = {
                'Name': clean_name,
                'Acronym': acronym,
                'About': description,
                'Email': email
            }
            clubs.append(club_data)
            print(f"Extracted: {clean_name} ({acronym})")
    
    return clubs


def upload_to_firestore(clubs):
    """
    Upload club data to Firestore clubs collection
    """
    # Initialize Firebase Admin SDK
    try:
        cred = credentials.Certificate('firebaseServiceKey.json')
        firebase_admin.initialize_app(cred)
    except Exception as e:
        print(f"Error initializing Firebase: {e}")
        return
    
    db = firestore.client()
    clubs_ref = db.collection('clubs')
    
    for club in clubs:
        try:
            # Check if club already exists by acronym
            existing = clubs_ref.where('Acronym', '==', club['Acronym']).limit(1).get()
            
            if existing:
                doc_id = existing[0].id
                # Update only empty fields
                update_data = {}
                existing_data = existing[0].to_dict()
                
                for key, value in club.items():
                    if value and not existing_data.get(key):
                        update_data[key] = value
                
                if update_data:
                    clubs_ref.document(doc_id).update(update_data)
                    print(f"Updated {club['Name']}: {list(update_data.keys())}")
                else:
                    print(f"Skipped {club['Name']}: all fields already populated")
            else:
                # Create new club document
                clubs_ref.add(club)
                print(f"Created new club: {club['Name']}")
                
        except Exception as e:
            print(f"Error processing {club['Name']}: {e}")


def main():
    print("Scraping Cal Poly CM student clubs...")
    clubs = scrape_cal_poly_clubs()
    
    print(f"\nExtracted {len(clubs)} clubs")
    
    # Save to JSON file for inspection
    with open('clubs_data.json', 'w', encoding='utf-8') as f:
        json.dump(clubs, f, indent=2, ensure_ascii=False)
    print("\nClub data saved to clubs_data.json")
    
    # Ask user if they want to upload to Firestore
    upload = input("\nUpload to Firestore? (y/n): ").strip().lower()
    if upload == 'y':
        upload_to_firestore(clubs)
    else:
        print("Skipped Firestore upload")


if __name__ == "__main__":
    main()
