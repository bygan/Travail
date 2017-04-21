import java.util.ArrayList;
import java.util.Iterator;
import java.lang.Iterable;

public class ABR {
    public static void main(String[] args) {
	ArrayList<String> ar = new ArrayList<String>();
	ar.add("schtroumpf");
	ar.add("java");
	ar.add("ornithorynque");
	ar.add("robot");
	ar.add("accordeon");
	Ensemble<String> e = new Ensemble<String>();
	for (String s : ar) { e.ajoute(s); }
	for (String s : e) { System.out.println(s); }
    }
}

class NotFound extends Exception {}
class Remplace extends Exception {
    private Arbre a;
    public Remplace(Arbre a) { this.a = a; }
    public Arbre getA() { return a; }
}

class Arbre<T extends Comparable<T>> {
    private T elt;
    private Arbre<T> fg = null;
    private Arbre<T> fd = null;
    private Arbre<T> pere;

    public Arbre(T e, Arbre<T> p) {
	this.elt = e;
	this.pere = p;
    }

    public T getElt() { return elt; }
    public boolean mem(T e) {
	if (e.compareTo(elt) == 0) { return true; }
	else if (e.compareTo(elt) < 0) { return (fg==null)?false:fg.mem(e); }
	else { return (fd==null)?false:fd.mem(e); }
    }
    public T get(T e) throws NotFound {
	if (e.compareTo(elt) == 0) { return elt; }
	else if (e.compareTo(elt) < 0) {
	    if (fg==null) { throw new NotFound(); }
	    else { return fg.get(e); }
	} else {
	    if (fd==null) { throw new NotFound(); }
	    else { return fd.get(e); }
	}
    }
    public T getMin() {
	return (fg==null)?elt:fg.getMin();
    }
    public T getMax() {
	return (fd==null)?elt:fd.getMax();
    }
    public void ajoute(T e) {
	// Remarque : comme les autres, cette méthode ne fonctionne que sur
	// un arbre non vide.
	if (e.compareTo(elt) < 0) {
	    if (fg==null) { fg = new Arbre<T>(e, this); }
	    else { fg.ajoute(e); }
	} else if (e.compareTo(elt) > 0) {
	    if (fd==null) { fd = new Arbre<T>(e, this); }
	    else { fd.ajoute(e); }
	} else {
	    // e.compareTo(elt) == 0
	    this.elt = e;
	}
    }


    // Stratégie :
    // - on cherche l'élément comme avec [mem] et on déclenche [NotFound] si non présent
    // - si l'élément, il faut en mettre un autre à la place
    //   + si le sous-arbre gauche est vide, on reconnecte directement le sous-arbre
    //     droit au noeud pere (on lève l'exception [Remplace] avec le sous-arbre droit
    //     en paramètre, que le noeud père rattrape pour faire le remplacement)
    //   + si le sous-arbre gauche n'est pas vide, on va chercher son plus grand élément
    //     et on le met dans le champ [elt] du noeud où on a trouvé [e], puis on
    //     supprime ce plus grand élément du sous-arbre.
    // Remarque sur "unchecked" : les classes d'exception ne peuvent pas être paramétrées,
    // donc l'élément [Arbre<T>] dans l'exception [Remplace] est déclaré comme [Arbre<Objet>].
    // Java émet un avertissement car la conversion de [Objet] à [T] peut échouer en théorie,
    // mais je supprime cet avertissement car le reste du code assure que nous n'utilisons
    // [Remplace] que dans des bonnes conditions.
    @SuppressWarnings("unchecked")
    public void retire(T e) throws NotFound, Remplace {
	if (e.compareTo(elt) < 0) {
	    if (fg==null) { throw new NotFound(); }
	    else {
		try { fg.retire(e); }
		catch (Remplace r) { fg = r.getA(); }
	    }
	} else if (e.compareTo(elt) > 0) {
	    if (fd==null) { throw new NotFound(); }
	    else {
		try { fd.retire(e); }
		catch (Remplace r) { fd = r.getA(); }
	    }
	} else {
	    if (fg==null) {
		if (fd!=null) { fd.pere = this.pere; }
		throw new Remplace(fd);
	    } else {
		T maxG = fg.getMax();
		elt = maxG;
		fg.retire(maxG);
	    }
	}
    }
    
    public void toArray(ArrayList<T> ar) {
	if (fg!=null) { fg.toArray(ar); }
	ar.add(elt);
	if (fd!=null) { fd.toArray(ar); }
    }

    // Fonctions auxiliaires de l'itérateur
    // - le noeud de départ est le noeud contenant l'élément minimum [getNoeudMin]
    // - [successeur] donne le noeud suivant (les successeurs successifs réalisent un
    //   parcours infixe de l'arbre)
    //   + si le sous-arbre droit n'est pas vide, aller y chercher le minimum [getNoeudMin]
    //   + sinon remonter au dernier noeud par rapport auquel on est dans un sous-arbre gauche [dernierBranchementGauche]
    //     et renvoyer [null] à défaut
    public Arbre<T> successeur() {
	return(fd==null)?dernierBranchementGauche():fd.getNoeudMin();
    }
    public Arbre<T> getNoeudMin() {
	return (fg==null)?this:fg.getNoeudMin();
    }
    public Arbre<T> dernierBranchementGauche() {
	if (pere==null) { return null; }
	return (pere.fg==this)?pere:pere.dernierBranchementGauche();
    }
}

class Ensemble<T extends Comparable<T>> implements Iterable<T> {
    private Arbre<T> a = null ;
	
    public boolean estVide() { return a==null; }
    // Au moment d'ajouter le premier élément il faut initialiser l'arbre.
    // Le reste du temps on se contente d'appeler la fonction ajout de l'arbre.
    public void ajoute(T e) {
	if (a==null) { a = new Arbre<T>(e, null); }
	else { a.ajoute(e); }
    }
    public boolean mem(T e) {
	if (a==null) { return false; }
	else { return a.mem(e); }
    }

    // Lorsque la racine de l'arbre se trouve dans le cas [Remplace] de la
    // méthode [Arbre.retire], il faut faire le remplacement en dur sur
    // l'attribut [a].
    // Cela arrive dans certains des cas où l'on veut retirer l'élément à
    // la racine, et en particulier lorsque l'on retire le dernier élément
    // de l'arbre.
    @SuppressWarnings("unchecked")
    public void retire(T e) throws NotFound {
	if (a==null) { throw new NotFound(); }
	else {
	    try { a.retire(e); }
	    catch (Remplace r) { a = r.getA(); }
	}
    }

    @SuppressWarnings("unchecked")
    public static Ensemble fromArray(ArrayList<Comparable> ar) {
	Ensemble ens = new Ensemble();
	for(Comparable e : ar) { ens.ajoute(e); }
	return ens;
    }
    public ArrayList<T> toArray() {
	ArrayList<T> ar = new ArrayList<T>();
	if (a != null) { a.toArray(ar); }
	return ar;
    }

    public IterateurArbre<T> iterator() { return new IterateurArbre<T>(a); }
}

class Association<C extends Comparable<C>, V> implements Comparable<Association<C, V>> {
    private C cle;
    private V valeur;
    public Association(C cle, V valeur) {
	this.cle = cle;
	this.valeur = valeur;
    }
    public boolean estCle(C c) { return this.cle == c; }
    public V getValeur() { return this.valeur; }
    public int compareTo(Association<C, V> acv) {
	return cle.compareTo(acv.cle);
    }
}

class Dictionnaire<C extends Comparable<C>, V> {
    private Arbre<Association<C, V>> a = null;

    public void vide() { a = null; }
    public boolean mem(C cle) {
	if (a==null) { return false; }
	else { return a.mem(new Association<C, V>(cle, null)); }
    }
    public void ajoute(C cle, V valeur) {
	Association<C, V> cv = new Association<C, V>(cle, valeur);
	if (a==null) { a = new Arbre<Association<C, V>>(cv, null); }
	else { a.ajoute(cv); }
    }
    @SuppressWarnings("unchecked")
    public void retire(C cle) throws NotFound {
	if (a==null) { throw new NotFound(); }
	else {
	    try { a.retire(new Association<C, V>(cle, null)); }
	    catch (Remplace r) { a = r.getA(); }
	}
    }
}


class IterateurArbre<T extends Comparable<T>> implements Iterator<T> {
    // L'itérateur mémorise uniquement le noeud courant, qui sert de point d'entrée au reste de l'arbre.
    // La fonction auxiliaire [Arbre.successeur] permet ensuite de naviguer.
    private Arbre<T> noeudCourant;

    public IterateurArbre(Arbre<T> a) {
	this.noeudCourant = (a==null)?null:a.getNoeudMin();
    }

    public boolean hasNext() { return this.noeudCourant != null; }
    public T next() {
	T next = noeudCourant.getElt();
	noeudCourant = noeudCourant.successeur();
	return next;
    }
}
