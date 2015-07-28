# coding: utf-8

import json

def parse():
    with file("rowdata.txt", "r") as fp:
        datas = json.loads(fp.read())

    final_data = {}
    for data in datas:
        year, month, day = tuple(data[0].split('/'))
        date = "-".join([year, month])
        aqi = data[1]

        if not final_data.get(date, None):
            final_data[date] = [0,0,0,0,0,0]

        if 0 <= aqi <= 50:
            final_data[date][0] += 1
        elif 50 < aqi <= 100:
            final_data[date][1] += 1
        elif 100 < aqi <= 150:
            final_data[date][2] += 1
        elif 150 < aqi <= 200:
            final_data[date][3] += 1
        elif 200 < aqi <= 300:
            final_data[date][4] += 1
        elif aqi > 300:
            final_data[date][5] += 1

    print json.dumps(final_data)


if __name__ == '__main__':
    parse()