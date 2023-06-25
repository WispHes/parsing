import requests
from bs4 import BeautifulSoup
import csv


HOST = 'https://4lapy.ru/'
HEADERS= {
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'User-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 YaBrowser/23.5.1.762 Yowser/2.5 Safari/537.36'
}

items = {
    "id товара": [],
    "наименование": [],
    "ссылка на товар": [],
    "регулярная цена": [],
    "промо цена": [],
    "бренд": [],
}


def get_html(url):
    r = requests.get(url, headers=HEADERS)
    return r.text


def get_all_links(url):
    links = []
    soup = BeautifulSoup(get_html(url), 'lxml')
    href = soup.find(
       'div', class_='b-filter__wrapper'
    ).find_all(
       'a', class_='b-filter-link-list__link'
    )
    for h in href:
        links.append(HOST + h.get('href'))
    return links


def pars_pagination(urls):
    links = []
    for url in urls:
        soup = BeautifulSoup(get_html(url), 'lxml')

        get_page = soup.find_all('div', class_='b-page-wrapper')
        for i in get_page:
            qty = i.find('span', class_='b-catalog-filter__label').text.split()
            if int(qty[0]) > 100:
                pagination_count = int(
                    i.find(
                        'ul', class_='b-pagination__list'
                    ).find_all('a')[-2].text.strip()
                )
                for page in range(1, pagination_count + 1):
                    ur = f'{url}?page={page}'
                    links.append(ur)
        break
    return links


def pars_true_categ(urls):
    links = []
    for url in urls:
        soup = BeautifulSoup(get_html(url), 'lxml')
        get_item = soup.find(
            'main', class_='b-catalog__main'
        ).find_all('div', class_='b-common-item__image-wrap')
        for i in get_item:
            link = i.find('a', class_='b-common-item__image-link').get('href')
            links.append(HOST + link)
    return links


def get_result(urls):
    for url in urls:
        soup = BeautifulSoup(get_html(url), 'lxml')
        if int(
            soup.find('input', class_='b-plus-minus__count')['data-cont-max']
        ) > 0:

            pomo_price = soup.find(
                'span', class_='b-product-information__price'
            ).text
            try:
                old_price = soup.find(
                    'span', class_='b-product-information__old-price'
                ).text
            except Exception:
                old_price = pomo_price
                pomo_price = 'not_pomo_price'

            get_description = soup.find(
                'div',
                class_='b-description-tab__column b-description-tab__column--characteristics'
            ).find_all('li', class_='b-characteristics-tab__item')

            for i in get_description:
                des = i.find(
                    'div', class_='b-characteristics-tab__characteristics-text'
                ).text.strip()
                if des == 'Артикул':
                    get_id = i.find(
                        'div',
                        class_='b-characteristics-tab__characteristics-value'
                    ).text.strip()
                if des == 'Бренд':
                    get_brend = i.find(
                        'div',
                        class_='b-characteristics-tab__characteristics-value'
                    ).text.strip()

            items['id товара'].append(str(get_id))
            items['наименование'].append(str(url))
            items['ссылка на товар'].append(
                str(soup.find('h1', class_='b-title').text)
            )
            items['регулярная цена'].append(str(old_price))
            items['промо цена'].append(str(pomo_price))
            items['бренд'].append(str(get_brend))


def write_csv():
    with open('data.csv', 'w', newline='') as file:
        writer = csv.writer(file, delimiter=',')
        writer.writerow(
            ['id товара', 'наименование',
                'ссылка на товар', 'регулярная цена',
                'промо цена', 'бренд']
        )
        for i in range(len(items['ссылка на товар'])):
            writer.writerow(
                [items['id товара'][i], items['наименование'][i],
                    items['ссылка на товар'][i], items['регулярная цена'][i],
                    items['промо цена'][i], items['бренд'][i]]
            )


if __name__ == '__main__':
    link_of_categ = get_all_links('https://4lapy.ru/catalog')
    get_result(pars_true_categ(pars_pagination(link_of_categ)))
    write_csv()
