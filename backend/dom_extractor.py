import asyncio
from playwright.async_api import async_playwright
from bs4 import BeautifulSoup

async def extract_and_clean_dom(url):
    print(f"Launching browser to scrape: {url}")
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        
        # Wait for the network to idle so dynamic JavaScript content loads
        await page.goto(url, wait_until="networkidle")
        raw_html = await page.content()
        await browser.close()

        print("DOM captured. Cleaning noisy tags...")
        # Clean the DOM using BeautifulSoup
        soup = BeautifulSoup(raw_html, 'html.parser')

        # Strip out tags that the AI doesn't need for WCAG accessibility checks
        for tag in soup(['script', 'style', 'svg', 'noscript', 'meta', 'link']):
            tag.decompose()

        # Remove empty elements to save token space
        for tag in soup.find_all(lambda t: not t.contents and not t.name in ['img', 'input', 'br', 'hr']):
             tag.decompose()

        cleaned_html = str(soup)
        return cleaned_html

if __name__ == "__main__":
    # Let's test it on a standard website
    target_url = "https://en.wikipedia.org/wiki/Accessibility" 
    
    # Run the async function
    cleaned_dom = asyncio.run(extract_and_clean_dom(target_url))
    
    print("\n--- Extraction Complete ---")
    print(f"Total characters in cleaned DOM: {len(cleaned_dom)}")
    print("Preview of the first 500 characters:")
    print(cleaned_dom[:500])