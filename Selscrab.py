import xml.etree.ElementTree as ET # Import von xml.etree.ElementTree as ET um XML-Datein zu erzeugen und zu manipulieren
from selenium import webdriver # Import webdriver von Selenium für automatisierte Browserinteraktionen
from selenium.webdriver.chrome.service import Service as ChromeService # Chromeservice um Chrome Webdriver-Dienst zu starten
from selenium.webdriver.common.by import By # 'By' ermöglicht die Lokalisierung von Elementen auf einer Webseite (CSS, XPath)
from selenium.webdriver.chrome.options import Options # 'Options' zum Festlegen von Optionen für den Chrome-Browser (User-Agent)
import time # zum einsetzten von Wartezeiten zwischen den Linkaufrufen
import random

def setup_driver():
    chrome_options = Options() # Erstellen des Options-Objekts
    # Folgende Zeile täuscht vor, das Der Browser auf einem Windows 10-System ist zur Vermeidung, sonst ist die Datenakquise nicht möglich
    chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.150 Safari/537.36")
    # Folgende Zeile führt zum Pfad beim dem sich 'chromedriver.exe' befindet
    service = ChromeService(executable_path="C:\\Program Files (x86)\\chromedriver\\chromedriver.exe")
    driver = webdriver.Chrome(service=service, options=chrome_options) # 'webdriver.Chrome' startet neues Objekt des Chrome-Browsers
                                                                       # 'service=service' übergibt den zuvor erstellten ChromeService an den WebDriver.
                                                                       # 'options=chrome_options übergibt die konfigurierten Chrome-Optionen an den WebDriver.
    return driver # Funktion gibt 'driver' zurück, welches den gestarteten und konfigurierten Chrome-Browser darstellt. Benötigt zum Laden von Seiten, Finden von Elementen usw.

def parse_results(driver, links, race_name):
    root = ET.Element("race_results") # Erstellen des XML-Elements 'race_results'
    for url in links: # Iteriert über jede URL in der Liste Links
        try:          # 'try', damit Code ausgeführt selbst wenn ein Fehler auftritt (z.B. wenn ein Element nicht gefdunen wird)
            driver.get(url) # lädt die Webseite mit der URL
            time.sleep(random.randint(5, 10)) # Wartet zufällige Zeit zwischen 5s-10s um kurzzeitige Anfragen zu vermeiden
            rows = driver.find_elements(By.CSS_SELECTOR, 'tr.autoqual') # findet alle Zeilen <tr> mit der CSS-Klasse 'autoqual'
            for row in rows: # Iteriert über jede gefundene Zeile
                # Extrahiert die Daten aus den Tabellenzellen <td>. X.PATH wird verwendet um die spezifische Zelle innerhalb einer Zeile zu finden
                overall_time = row.find_element(By.XPATH, './td[7]').text # Extrahiert die Gesamtzeit
                swim_time = row.find_element(By.XPATH, './td[9]').text # Extrahiert die Schwimmzeit
                bike_time = row.find_element(By.XPATH, './td[11]').text # Extrahiert die Fahrradzeit
                run_time = row.find_element(By.XPATH, './td[13]').text # Extrahiert die Laufzeit
                age_group = row.find_element(By.XPATH, './td[5]/a').text # Extrahiert die Altergruppe
                gender = row.find_element(By.XPATH, './td[4]').text  # Extrahiere das Geschlecht

                # Erstellt ein neues 'result'-Element als Kindelement von 'race_results'
                result = ET.SubElement(root, "result")
                ET.SubElement(result, "overall_time").text = overall_time
                ET.SubElement(result, "swim_time").text = swim_time
                ET.SubElement(result, "bike_time").text = bike_time
                ET.SubElement(result, "run_time").text = run_time
                ET.SubElement(result, "age_group").text = age_group
                ET.SubElement(result, "gender").text = gender
        except Exception as e: # Falls ein Fehler beim Laden der URL oder Extraktion der Daten auftritt, wird Fehlertext ausgegeben
            print(f"Fehler beim Laden von {url}: {e}")

    if len(root): # root= Wurzelelement: 'race_results'. len(root) gibt Anzahl der direkten Kindelemente zurück. Prüft ob 'root' mindestens 1 Kindelement hat
        filename = f"{race_name.replace(' ', '_').lower()}_results.xml" # Wenn Kindelement enthalten, wird Dateiname basierend auf 'race_name' erstellt .lower für Kleinschreibung
        tree = ET.ElementTree(root) # Erstellt einen Zweig im 'race_result'-Wurzelelement
        tree.write(filename, encoding="utf-8", xml_declaration=True) # Speicherung der Textdaten
        print(f"XML-Datei '{filename}' wurde gespeichert.") # Bestätigung wird ausgegeben
    else:
        print("Keine Daten extrahiert für ", race_name) # Ansonsten wird Fehlermeldung ausgegeben

def main():
    driver = setup_driver() # Ruft die setup_driver Funktion und erstellt Objekt 'driver'
    try: # Um sicherzustellen, das WebDriver beendet wird, selbst wenn Fehler auftritt.
        links = [] # Liste für die Links wird erstellt
        race_name = "" # String, der aktuelles Rennen speichert.
        with open("links.txt", "r") as file: # Öffnet die Datei links.txt
            for line in file: # Läuft über jede Zeile in der Datei
                line = line.strip() # Liest Zeile und entfernt Leerzeichen aus der Zeile
                if line.endswith(':'): # Überprüft, ob Zeile mit einem Doppelpunkt endet -> Indikator für neues Rennen
                    if links: # Wenn 'links' nicht leer, dann wird durchgeführt.
                        parse_results(driver, links, race_name) # Argumente werden Funktion pare_results übergeben
                        links = [] # Leert die Liste für nächstes Rennen
                    race_name = line[:-1].strip() # Speichert den Rennnamen ohne Doppelpunkt
                elif line: # Falls Zeile nicht leer ist und nicht mit Doppelpunkt endet, wird sie als URL in die links Liste aufgenommen
                    links.append(line)
        if links: # Wenn links noch Einträge enthalten sollte, werden sie an parse_result übergeben
            parse_results(driver, links, race_name)
    finally: # Wird immer ausgeführt, unabhängig ob Fehler aufgetreten
        driver.quit() # Beendet WebDriver und schließt Browser

if __name__ == "__main__": # Stellt sicher, dass die main-Funktion nur bei direkter Ausführung des Skripts gestartet wird
    main()




















