#insert doomsday data into firestore
#this data will be used by the app to create Doomsday objects and display them to the user

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import datetime
import json

# Use a service account
cred = credentials.Certificate('/home/j3rk/Desktop/programming.local/doomsday_app/firebase/doomsday-app-1970042419fa.json')

app = firebase_admin.initialize_app(cred)

db = firestore.client()

# add doomsday data to firestore
def add_doomsday_data():
    # read doomsday data from JSON file
    with open('/home/j3rk/Desktop/programming.local/doomsday_app/firebase/doomsday_data.json') as f:
        data = json.load(f)

    # add doomsday data to firestore
    for doomsday in data:
        print("Adding doomsday data to firestore: " + str(doomsday))
        db.collection(u'doomsday').add(doomsday)
        
# modify a field in a collection matching a query
def modify_field(collection, query_field, query_value, field, value):
    docs = db.collection(collection).where(query_field, '==', query_value).stream()
    for doc in docs:
        doc.reference.update({field: value})
        
#delete a collection
def delete_collection(coll_name):
    docs = db.collection(coll_name).stream()
    for doc in docs:
        doc.reference.delete()
        
add_doomsday_data()
#delete_collection('doomsday')