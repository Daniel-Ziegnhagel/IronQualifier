import xml.etree.ElementTree as ET  # XML-Verarbeitung
from selenium import webdriver  # Webdriver für Browserinteraktionen
from selenium.webdriver.chrome.service import Service as ChromeService  # Chrome Webdriver-Dienst
from selenium.webdriver.common.by import By  # Element-Lokalisierung
from selenium.webdriver.chrome.options import Options  # Chrome-Optionen
import time  # Wartezeiten
import random  # Zufallszeiten

def setup_driver():
    chrome_options = Options()
    chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                                "AppleWebKit/537.36 (KHTML, like Gecko) "
                                "Chrome/88.0.4324.150 Safari/537.36")
    service = ChromeService(executable_path="C:\\Program Files (x86)\\chromedriver\\chromedriver.exe")
    driver = webdriver.Chrome(service=service, options=chrome_options)
    return driver

def parse_results(driver, links, race_name):
    root = ET.Element("race_results")
    for url in links:
        try:
            driver.get(url)
            time.sleep(random.randint(5, 10))
            rows = driver.find_elements(By.CSS_SELECTOR, 'tr.autoqual')
            for row in rows:
                overall_time = row.find_element(By.XPATH, './td[7]').text
                swim_time = row.find_element(By.XPATH, './td[9]').text
                bike_time = row.find_element(By.XPATH, './td[11]').text
                run_time = row.find_element(By.XPATH, './td[13]').text
                age_group = row.find_element(By.XPATH, './td[5]/a').text
                gender = row.find_element(By.XPATH, './td[4]').text

                result = ET.SubElement(root, "result")
                ET.SubElement(result, "overall_time").text = overall_time
                ET.SubElement(result, "swim_time").text = swim_time
                ET.SubElement(result, "bike_time").text = bike_time
                ET.SubElement(result, "run_time").text = run_time
                ET.SubElement(result, "age_group").text = age_group
                ET.SubElement(result, "gender").text = gender
        except Exception as e:
            print(f"Fehler beim Laden von {url}: {e}")

    if len(root):
        filename = f"{race_name.replace(' ', '_').lower()}_results.xml"
        tree = ET.ElementTree(root)
        tree.write(filename, encoding="utf-8", xml_declaration=True)
        print(f"XML-Datei '{filename}' wurde gespeichert.")
    else:
        print("Keine Daten extrahiert für ", race_name)

def main():
    driver = setup_driver()
    try:
        links = []
        race_name = ""
        with open("links.txt", "r") as file:
            for line in file:
                line = line.strip()
                if line.endswith(':'):
                    if links:
                        parse_results(driver, links, race_name)
                        links = []
                    race_name = line[:-1].strip()
                elif line:
                    links.append(line)
        if links:
            parse_results(driver, links, race_name)
    finally:
        driver.quit()

if __name__ == "__main__":
    main()




















