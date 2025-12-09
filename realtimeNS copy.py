from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from bs4 import BeautifulSoup
import time

# Selenium 옵션 설정
options = Options()
options.add_argument('--headless')  # 브라우저 창을 띄우지 않음
options.add_argument('--disable-gpu')
options.add_argument('--no-sandbox')

# 웹드라이버 경로 설정 (ChromeDriver의 경로를 지정해야 합니다)
driver = webdriver.Chrome(options=options)

try:
    url = "https://www.coinreaders.com/sub_view.html"
    driver.get(url)

    # 페이지가 완전히 로딩될 때까지 대기
    time.sleep(5)  # 필요에 따라 조절

    # 페이지 소스 가져오기
    html = driver.page_source
    soup = BeautifulSoup(html, "html.parser")

    # 기사 목록 선택자 (웹페이지 구조에 따라 조정 필요)
    articles = soup.select("div.all_list .news_list a")

    print(f"기사 개수: {len(articles)}")
    for a in articles[:3]:
        href = a.get("href")
        title = a.get_text(strip=True)
        print(f"{href} - {title}")

finally:
    driver.quit()
