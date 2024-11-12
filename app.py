from flask import Flask, render_template, request
import mysql.connector

app = Flask(__name__)

# Configuration de la connexion à la base de données
db = mysql.connector.connect(
    host="127.0.0.1",
    user="root",
    passwd="",
    database="db2_projet_long"
)


@app.route('/', methods=['GET'])
def index():
    curseur = db.cursor()
    curseur.execute("SELECT id FROM commande_en_attente")
    resultat = curseur.fetchall()
    return render_template('index.html', enProgres=len(resultat))

#Page qui permet d'ajouter une commande
@app.route('/ajouter')
def ajouter():
    curseur = db.cursor()
    curseur.execute("SELECT * FROM croute") #fetch les types de croutes
    croutes = curseur.fetchall()
    curseur.execute("SELECT * FROM sauce") #fetch les types de sauces
    sauces = curseur.fetchall()
    curseur.execute("SELECT * FROM garniture") #fetch les types de garnitures
    garnitures = curseur.fetchall()
    return render_template('ajouter.html', croutes=croutes, sauces=sauces, garnitures=garnitures) #affiche la page

@app.route('/processPost', methods=['POST'])
def pp():
    if request.form["action"] == "ajouter":
        curseur = db.cursor()
        commande = {
            "croute"    : request.form["croute"],
            "sauce"     : request.form["sauce"],
            "garniture1": request.form["garniture1"],
            "garniture2": request.form["garniture2"],
            "garniture3": request.form["garniture3"],
            "garniture4": request.form["garniture4"],
            "nom"       : request.form["nom"],
            "adresse"   : request.form["adresse"],
            "telephone" : request.form["telephone"]
        }

        req = "CALL ajout_commande(%(croute)s, %(sauce)s, %(garniture1)s, %(garniture2)s, %(garniture3)s, %(garniture4)s, %(nom)s, %(adresse)s, %(telephone)s)"
        curseur.execute(req, commande)



        #conversion des donnés pour faciliter la lecture (id -> nom)
        req = "SELECT * FROM croute WHERE id = %(croute)s"
        curseur.execute(req, commande)
        commande["croute"] = curseur.fetchall()[0][1]

        req = "SELECT * FROM sauce WHERE id = %(sauce)s"
        curseur.execute(req, commande)
        commande["sauce"] = curseur.fetchall()[0][1]

        req = "SELECT * FROM garniture WHERE id = %(garniture1)s"
        curseur.execute(req, commande)
        commande["garniture1"] = curseur.fetchall()[0][1]

        req = "SELECT * FROM garniture WHERE id = %(garniture2)s"
        curseur.execute(req, commande)
        commande["garniture2"] = curseur.fetchall()[0][1]

        req = "SELECT * FROM garniture WHERE id = %(garniture3)s"
        curseur.execute(req, commande)
        commande["garniture3"] = curseur.fetchall()[0][1]

        req = "SELECT * FROM garniture WHERE id = %(garniture4)s"
        curseur.execute(req, commande)
        commande["garniture4"] = curseur.fetchall()[0][1]

        return render_template('retour_commande.html', commande=commande)

    elif request.form["action"] == "completion":
        curseur = db.cursor()
        req = "DELETE FROM commande_en_attente WHERE id = %(id)s"
        curseur.execute(req, {"id":request.form["index"]})
        return consulter()
    

@app.route('/consulter')
def consulter():
    curseur = db.cursor()
    curseur.execute("SELECT nom, adresse, commande_en_attente.id FROM client INNER JOIN commande ON client.id = commande.client_id INNER JOIN commande_en_attente ON commande.id = commande_en_attente.commande_id")
    resultat = curseur.fetchall()
    return render_template('consulter.html', resultat = resultat)

@app.route('/details', methods=['POST'])
def details():
    curseur = db.cursor()
    #grosse bertha
    req = "SELECT commande_en_attente.id, client.nom, adresse, telephone, croute.nom, sauce.nom FROM client INNER JOIN commande ON client.id = commande.client_id INNER JOIN commande_en_attente ON commande_en_attente.commande_id = commande.id INNER JOIN pizza ON commande.id = pizza.commande_id INNER JOIN sauce ON sauce.id = pizza.sauce_id INNER JOIN croute ON croute.id = pizza.croute_id WHERE commande_en_attente.id = %(id)s ORDER BY commande_en_attente.id DESC LIMIT 1"
    id = request.form["id"]
    curseur.execute(req, {"id":id})
    data = curseur.fetchall()

    req = "SELECT * FROM garniture INNER JOIN pizza_garniture ON garniture.id = pizza_garniture.garniture_id INNER JOIN pizza ON pizza.id = pizza_garniture.pizza_id INNER JOIN commande ON commande.id = pizza.commande_id INNER JOIN commande_en_attente ON commande_en_attente.commande_id = commande.id WHERE commande_en_attente.id = %(id)s"
    print(id)
    curseur.execute(req, {"id":id})
    garnitures = curseur.fetchall()

    return render_template('details.html', data=data, garnitures=garnitures)

if __name__ == '__main__':
    app.run(debug=True)

db.close()