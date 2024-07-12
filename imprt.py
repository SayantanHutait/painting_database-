import pandas as pd
from sqlalchemy import create_engine

file_names = [
    "artist.csv",
    "canvas_size.csv",
    "image_link.csv",
    "museum.csv",
    "museum_hours.csv",
    "product_size.csv",
    "subject.csv",
    "work.csv"
]

db = create_engine('postgresql://postgres:root@localhost/painting')
conn = db.connect()
for  f in file_names:
    df = pd.read_csv(f'E:\Python DS\painting\{f}')
    df.to_sql(f.split('.')[0],con=conn,if_exists='replace',index=False)
                     





