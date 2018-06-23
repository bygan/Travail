PImage dst;


int gridW, gridH;
int cellWidth, cellHeight;
int leftMargin, topMargin;

int cellCX, cellCY;
int cellDX, cellDY;

// tout ce qu'il faut pour piloter une animation
float propAnim      = 0.0; 
boolean animRunning = false;
int NONE            = 0;
int FALLING         = 1;
int LASER           = 2;
int HORI            = 3;
int VERT            = 4;
int SQBOOM          = 5;
int SQDBLBOOM       = 6;
int STARCROSS       = 7;
int BIGBONBON       = 8;
int ALLSTRIP        = 9;
int ALLSTRIP2       = 10;
int ALLSTRIP3       = 11;
int DOUBLELASER     = 12;
int SUPERLASER      = 13;

int SEUIL1          = 14;
int SEUIL2          = 15;
int SEUIL3          = 16;

int score;
int seuil1;
int seuil2;
int seuil3;
int nbCoups;
int seuilAtteint;


int animType        = NONE;
int animCount       = 0;
int EMPTY           = -1;
 // infos utiles pour afficher l'animation
int animi=-1, animj=-1;   // l'endroit ou on declenche l'animation
int animi2=-1, animj2=-1; // l'autre bonbon mitoyen qui a peut etre une influence sur l'animation

int maxElemTypes  = 5; // 5 types = rouge, vert, bleu, violet, jaune.
int maxAvailTypes = 5; // un niveau n'utilise pas toujours tous les types possibles
int maxBonusTypes = 5; // normale, rayee H, rayeeV, "en sachet", en boule choco

 // liste des images avec toutes les versions bonus
PImage imgs[][] = new PImage [maxBonusTypes+1][maxElemTypes];


// noyau gaussien de rayon 2 .. pour les flous et les ombres
int[][] gKern = {{1,4,7,4,1}, {4, 16, 26, 16,4}, {7, 26, 41, 26, 7}, {4, 16, 26, 16,4}, {1,4,7,4,1}};

// la grille de bonbons ... a detruire
int[][] grid; 

// la grille des decallages a appliquer (temporairement) a l'affichage bonbons
int[][] gridDec; 





void setupLevel1(){
  // on utilise tous les types de bonbons disponibles
  maxAvailTypes = maxElemTypes;
  score =0 ;
  seuil1 = 5000;
  seuil2 = 10000;
  seuil3 = 250000;
  nbCoups = 10;
  seuilAtteint = 0;
  
  for(int j=0; j<gridH; j++)
    for(int i=0; i<gridW; i++) {
      grid[j][i] = EMPTY;
      gridDec[j][i] = 0*cellWidth+0;//wait to valid 
    }
      
  // remplissage aleatoire
  randomSeed(2);
  for(int j=0; j<gridH; j++)
    for(int i=0; i<gridW; i++){
      do {
        grid[j][i] = int(random(0, maxAvailTypes));
      } while (crushable(i, j));
    }
    
  grid[4][3] = 2;
  grid[5][2] = 2;
  grid[2][2] = 1+maxElemTypes*2;
  grid[2][3] = 1+maxElemTypes*4;  
  grid[2][4] = 1+maxElemTypes*4;
  grid[2][5] = 1+maxElemTypes*3;  
}////////////////////////////


PImage creerVersionOmbree(PImage src){
  PImage dst = createImage(src.width+4, src.height+4, ARGB);
  dst.loadPixels();
  for (int j=0; j<src.height; j++) {
    for (int i=0; i<src.width; i++) {
      
      float acc = 0;
      for (int dj=-2; dj<=2; dj++)
        for (int di=-2; di<=2; di++) 
          if ((i+di)>=0 && (i+di)<cellWidth && (j+dj)>=0 && (j+dj)<cellHeight)
            acc+=  gKern[dj+2][di+2]*alpha(src.pixels[(i+di)+(j+dj)*src.width]);
      acc = acc/273;
      dst.pixels[i+2+(j+2)*dst.width] = color(0, 0, 0, acc); 
    }
  }

  for (int j=0; j<src.height; j++) {
    for (int i=0; i<src.width; i++) {
      if (alpha(src.pixels[(i)+(j)*src.width])>0)
        dst.pixels[i+2+(j+2)*dst.width] = src.pixels[(i)+(j)*src.width]; 
    }
  }
  dst.updatePixels();
  return dst;
}////////////////////////////


PImage creerVersionRayeeVertical(PImage src,int type){
  PImage dst = createImage(src.width, src.height, ARGB);
  dst.loadPixels();
  for (int j=0; j<src.height; j++) {
    for (int i=0; i<src.width; i++) {
      float r = red  (src.pixels[i+j*src.width]);
      float g = green(src.pixels[i+j*src.width]);
      float b = blue (src.pixels[i+j*src.width]);
      float a = alpha (src.pixels[i+j*src.width]);
      
      // T2.2
      
      float xv=cellWidth/2-cellWidth;  //création d'un point qui sert à faire des courbes verticales
      float yv=cellWidth/2;
      
      float distance=dist(xv,yv,i,j)/2;  //distance entre le point crée et le point de cordonée i;j. On a divisé par2 pour que les courbes soient plus espacées
      
      float pr = (3*r/4)*(1-sin(distance)*sin(distance))+255-3*(255-r)/4*sin(distance)*sin(distance);
      float pg = (3*g/4)*(1-sin(distance)*sin(distance))+255-3*(255-g)/4*sin(distance)*sin(distance);
      float pb = (3*b/4)*(1-sin(distance)*sin(distance))+255-3*(255-b)/4*sin(distance)*sin(distance);
      //On a remplacé la boucle if par une moyenne pondérée pour chaque coumeur entrre la couleur la plus sombre et la couleur la plus colorée pour obtenir des bandes moins crénelées.
      //On utilise sin*sin pour être sûre que la valeur obtenue soit entre 0 et 1
      
      dst.pixels[i+j*src.width]=color(pr,pb,pg,a);
    }
  }      
  dst.updatePixels();
  return dst;

}////////////////////////////


PImage creerVersionRayeeHorizontal(PImage src,int type){
  PImage dst = createImage(src.width, src.height, ARGB);
  dst.loadPixels();
  for (int j=0; j<src.height; j++) {
    for (int i=0; i<src.width; i++) {
      float r = red  (src.pixels[i+j*src.width]);
      float g = green(src.pixels[i+j*src.width]);
      float b = blue (src.pixels[i+j*src.width]);
      float a = alpha (src.pixels[i+j*src.width]);
      
      // T2.2
      
      float xh=cellWidth/2;  //création d'un point qui sert à faire des courbes verticales
      float yh=cellWidth/2-cellWidth;
      
      float distance=dist(xh,yh,i,j)/2;  //distance entre le point crée et le point de cordonée i;j. On a divisé par2 pour que les courbes soient plus espacées
      
      float pr = (3*r/4)*(1-sin(distance)*sin(distance))+255-3*(255-r)/4*sin(distance)*sin(distance);
      float pg = (3*g/4)*(1-sin(distance)*sin(distance))+255-3*(255-g)/4*sin(distance)*sin(distance);
      float pb = (3*b/4)*(1-sin(distance)*sin(distance))+255-3*(255-b)/4*sin(distance)*sin(distance);
      //On a remplacé la boucle if par une moyenne pondérée pour chaque coumeur entrre la couleur la plus sombre et la couleur la plus colorée pour obtenir des bandes moins crénelées.
      //On utilise sin*sin pour être sûre que la valeur obtenue soit entre 0 et 1
      
      dst.pixels[i+j*src.width]=color(pr,pb,pg,a);
    }
  }      
  dst.updatePixels();
  return dst;

}////////////////////////////


PImage creerVersionSachet(PImage src,int type){
  println("");
  PImage dst = createImage(src.width, src.height, ARGB);
  dst.loadPixels();
  int col = src.pixels[src.width/2+src.height/3*src.width];
  //float rcol = red   (col)/2;
  //float gcol = green (col)/2;
  //float bcol = blue  (col)/2;
  for (int j=0; j<src.height; j++) {
    for (int i=0; i<src.width; i++) {
      float r = red   (src.pixels[i+j*src.width]);
      float g = green (src.pixels[i+j*src.width]);
      float b = blue  (src.pixels[i+j*src.width]);
      float a = alpha (src.pixels[i+j*src.width]);
      float i0 = i-cellWidth/2;
      float j0 = j-cellHeight/2;
      float j1 = j-2*cellHeight/3;
      // T2.5
      
      float dist = (3*(Math.max(Math.abs(i0), Math.abs(j0)))+sqrt(i0*i0+j0*j0))/2.0;
      if (dist < float(cellWidth)/1.0) {
        if (alpha(src.pixels[i+j*src.width])>0){
          dst.pixels[i+j*src.width] = color(255-(255-r)/2, 255-(255-g)/2, 255-(255-b)/2, a); 
        } else {
          dst.pixels[i+j*src.width] = color(red(col), green(col),blue(col), 128); 
        }
      }    
    }
  }
  dst.updatePixels();
  return dst;
}////////////////////////////


PImage creerVersionChoco(PImage src,int type){
  PImage dst = createImage(src.width, src.height, ARGB);
  int col = src.pixels[src.width/2+src.height/3*src.width];
  dst.loadPixels();
  for (int j=0; j<src.height; j++) {
    for (int i=0; i<src.width; i++) {
      float i0 = i-src.width/2;
      float j0 = j-src.height/2;
      float i1 = i-src.width/3;
      float j1 = j-src.height/3;
      
      float dist0 = sqrt(i0*i0+j0*j0);
      float dist1 = sqrt(i1*i1+j1*j1)/2.0;
      float dist2 = 0.8-(sqrt(i*i+j*j)/(src.width*src.height)/2.0);
      float lum = 1.15*(1+(dist1+1)/(dist1*dist1+dist1+1));
      if (dist0 < float(src.width)/2.0-3) {
         dst.pixels[i+j*src.width] = color(128-3*dist1, 64, dist1); 
      }      
    }
  }
  dst.updatePixels();
  return dst;
}////////////////////////////


PImage creerVersionSimple(float C0, float C1, float C2, float C3, float SUMW, float r0, float g0, float b0){
  PImage dst = createImage(cellWidth, cellHeight, ARGB);
  dst.loadPixels();
  
  for (int j=1; j<cellHeight; j++) 
    for (int i=1; i<cellWidth; i++) {
      float i0 = i-cellWidth/2;
      float j0 = j-cellHeight/2;
      float j1 = j-2*cellHeight/3;
      
      float dist = C0 * Math.max(Math.abs(i0), Math.abs(j0))+
                   C1 * 0.5*(Math.abs(i0)+Math.abs(j0))+
                   C2 * sqrt(i0*i0+j0*j0)+
                   C3 * sqrt(i0*i0+j1*j1)*abs(2*j0/cellHeight+2);
                   
      if (dist < float(cellWidth)/ (SUMW*(C0+C1+C2+C3)) ) {
        // ombrage haut-gauche vers bas-droit
        int lum = 128-(i*32/cellWidth)-(j*32/cellHeight);
        
        // plus epais au centre les bonbons sont donc un peu plus sombre au milieu
        lum =(4*lum+4*int(255*dist/(cellWidth/(SUMW*(C0+C1+C2+C3))) ))/9;

        // T2.4
         //pour rendre les bonbons plus foncées
         
         float r=96+lum*r0;
         float g=96+lum*g0;
         float b=96+lum*b0;
         float Max=max(r,g,b);
         float d=280-Max;
        
         dst.pixels[i+j*cellWidth] = color(2*lum*r0, 2*lum*g0, 2*lum*b0);
         
         float Rround;     
               Rround = dist(17,20,i,j);
         if(Rround<9){
           float r1=(255*(8-Rround)  +  Rround*(2*lum*r0))/8;
           float g1=(255*(8-Rround)  +  Rround*(2*lum*g0))/8;
           float b1=(255*(8-Rround)  +  Rround*(2*lum*b0))/8;//en utilisant le principe moyenne pondéréé
           dst.pixels[i+j*cellWidth] = color(r1,g1,b1);
         }
       }
     }

  dst.updatePixels();
  return dst;
}////////////////////////////


  PImage bg;


void setup(){
  size(1024, 768);
  
  
  bg = loadImage("backgroundimage.jpg");
  bg.resize(width,height);
 
  bg.loadPixels();
  for (int j=0; j < bg.height; j=j+1) {
    for (int i=0; i < bg.width; i=i+1) {
      int c = bg.pixels[i+j*bg.width];
      int a = (c&0xff000000)>>24;if (a<0) a+=128;
      int r = (c&0x00ff0000)>>16;if (r<0) r+=128;
      int g = (c&0x0000ff00)>>8; if (g<0) g+=128;
      int b = (c&0x000000ff)>>0; if (b<0) b+=128;
     
      int lum0=(r+g+b)/3;
      r=(lum0+r)/3;
      g=(lum0+g)/3;
      b=(lum0+b)/3;
      
      bg.pixels[i+j*bg.width] = (a<<24) + (r<<16) + (g<<8) + (b<<0);
    }
  }
  bg.updatePixels();
  noLoop();

  
  background(bg);

  // intitialisation des variables
  leftMargin = width/10;
  topMargin  = height/10;
  gridW      = 16;
  gridH      = 10;
  grid       = new int[gridH][gridW];
  gridDec    = new int[gridH][gridW];
  cellWidth  = (width-leftMargin)/gridW;
  cellHeight = (height-topMargin)/gridH;
  
  dst = createImage(cellWidth, cellHeight, ARGB);
  dst.loadPixels();
  
  for (int j=1; j<cellHeight; j++) 
    for (int i=1; i<cellWidth; i++) {
      float r = 70;
      float g = 100;
      float b = 240-j-i;
      dst.pixels[i+j*cellWidth] = color(r, g, b, 130);
    }
      dst.updatePixels();
      
      
      
  // on cree la version coloree de chaque bonbon avec une forme donnee par des poids sur les distances

      imgs[0][0] = creerVersionSimple(0, -2, 3, 0, 1.400, 1.0, 0.0, 0.0);
      imgs[0][1] = creerVersionSimple(0, 0,  1, 0, 2.300, 0.0, 1.0, 0.0);
      imgs[0][2] = creerVersionSimple(2, 3, -1, 0, 0.230, 0.0, 0.0, 1.0);
      imgs[0][3] = creerVersionSimple(3.1, 0.3, 0.3, 0.3, 0.150, 1.3, 1.5, 0); // T2.3
      imgs[0][4] = creerVersionSimple(0, 0,  0, 3, 0.135, 1.0, 0.0, 1.0);

  // puis on applique des filtres pour faire les images de chaque variante de chaque type
  for(int i=0; i<maxElemTypes; i++){
    imgs[1][i] = creerVersionOmbree(imgs[0][i]);
    imgs[2][i] = creerVersionOmbree(creerVersionRayeeHorizontal(imgs[0][i], i));
    imgs[3][i] = creerVersionOmbree(creerVersionRayeeVertical(imgs[0][i], i));
    imgs[4][i] = creerVersionOmbree(creerVersionSachet(imgs[1][i], i));// T2.5
    imgs[5][i] = creerVersionOmbree(creerVersionChoco(imgs[0][i], i));
  }
  
  setupLevel1();
  frameRate(25);
  noLoop();
}////////////////////////////


// compte combien de bonbons identiques sont alignes selon le vecteur di,dj
int countSame(int i, int j, int di, int dj){
  int count = 0;
  int type = grid[j][i]%maxElemTypes;
  
  while (j+(count+1)*dj>=0 && j+(count+1)*dj<gridH && 
         i+(count+1)*di>=0 && i+(count+1)*di<gridW && 
         grid[j+(count+1)*dj][i+(count+1)*di]%maxElemTypes==type &&
         grid[j+(count+1)*dj][i+(count+1)*di]<4*maxElemTypes){
    count++;
  }
  return count;
}////////////////////////////


// determine si une case est dans un alignement de 3
boolean crushable(int i, int j) {
  int hor = countSame(i, j, +1, 0) + countSame(i, j, -1, 0)+1;
  int ver = countSame(i, j, 0, +1) + countSame(i, j, 0, -1)+1;
  return  (hor>=3 || ver>=3);
}////////////////////////////


// determine si une case n'est pas "solide" pour porter le bonbon du dessus
boolean emptyOrFalling(int i, int j){
  if (i==animi && j==animj) return false;
  if (i==animi2 && j==animj2) return false;
  if (j==gridH-1) return (grid[j][i]==-1);
  else return (grid[j][i]==EMPTY) || emptyOrFalling(i, j+1) ;
}////////////////////////////


// determine si une case porte un bonbon raye (vertical ou horizontal)
boolean estRaye(int i, int j){
  return (grid[j][i]>maxElemTypes && grid[j][i]<3*maxElemTypes) ;
}////////////////////////////


// demarre les bonbons qui tombent et cree les bonbons en haut si necessaire
void updateGrid() {
  boolean moreToFall = false;
  int     falling    = 0;
  int     created    = 0;
  int     crushed    = 0;
  
  for(int j=gridH-1; j>=0; j--)
    for(int i=0; i<gridW; i++) {
      if (emptyOrFalling(i, j) && grid[j][i]!=EMPTY){ // une case vide(ou pleine d'un bonbon qui tombe) au dessous d'un bonbon le fait tomber !
        gridDec[j][i]= cellWidth; // T2.4
        falling++;
      } else if (grid[j][i]==EMPTY && j==0){
        grid[j][i] = int(random(0, maxAvailTypes));
        created++;
        if (emptyOrFalling(i, j)){
          gridDec[j][i]= cellWidth; // T2.4
          falling++;
        } else if(crushable(i, j)) 
          crushed += crush(i, j);
      }
    }

  if (crushed>0) updateGrid();
  if (falling>0){
    startAnim(40, FALLING, -1, -1, -1, -1);
  } else if (created>0)
    redraw();
}////////////////////////////


// demarre une animation avec tous les parametres fournis
void startAnim(int count, int type, int i, int j, int i2, int j2){
  //println("startAnim "+type+"  animRunning="+animRunning+" at "+i+", "+j+"=>"+grid[j][i]);
  if (!animRunning) {
    animRunning = true;
    animType    = type;
    animCount   = count;
    animi       = i;
    animj       = j;
    animi2      = i2;
    animj2      = j2;
    loop();
  }
}////////////////////////////


//// stop l'animation et enleve/mange les bonbons /////////////////
void stopAnim(){
  //println("stopAnim "+animRunning+" "+animType);
  if (animRunning) {
    animRunning = false;
    int aT = animType;
    animType = NONE;

    noLoop();
    //int old = grid[animj][animi];
    
    // selon le type d'animation, il ne faut pas enlever les memes bonbons
    if (aT==LASER) {
      int other = grid[animj2][animi2];
      grid[animj][animi] = EMPTY;      
      for (int j0=0; j0<gridH; j0++)
        for (int i0=0; i0<gridW; i0++){
          if (grid[j0][i0]%maxElemTypes == other%maxElemTypes && grid[j0][i0]<4*maxElemTypes)
            eat(i0, j0);
        }
    } else if (aT==HORI) {
      grid[animj][animi] = EMPTY;
      for (int i0=0; i0<gridW; i0++){
        eat(i0, animj);
      }
    } else if (aT==VERT) {
      grid[animj][animi] = EMPTY;
      for (int j0=0; j0<gridH; j0++){
        eat(animi, j0);
      }
    } else if (aT==SQBOOM) {
      grid[animj][animi] = EMPTY;
      for (int j0=max(0, animj-1); j0<=min(gridH-1, animj+1); j0++)
        for (int i0=max(0, animi-1); i0<=min(gridW-1, animi+1); i0++)
          eat(i0, j0);
    } else if (aT==SQDBLBOOM) {
      grid[animj][animi] = EMPTY;
      for (int j0=max(0, animj-2); j0<=min(gridH-1, animj+2); j0++)
        for (int i0=max(0, animi-2); i0<=min(gridW-1, animi+2); i0++){
          eat(i0, j0);
        }
    } else if (aT==STARCROSS) {
      grid[animj][animi] = EMPTY;
      for (int j0=0; j0<gridH; j0++)
        eat(animi, j0);
      for (int i0=0; i0<gridW; i0++)
        eat(i0, animj);  
    } else if (aT==BIGBONBON) {
      grid[animj][animi] = EMPTY;
      grid[animj2][animi2] = EMPTY;
      for (int j0=0; j0<gridH; j0++)
        for (int i0=max(0, animi-1); i0<=min(gridW-1, animi+1); i0++)
          eat(i0, j0);
      for (int i0=0; i0<gridW; i0++)
        for (int j0=max(0, animj-1); j0<=min(gridH-1, animj+1); j0++)
          eat(i0, j0);
    } else if (aT==SUPERLASER) {
      grid[animj][animi] = EMPTY;
      grid[animj2][animi2] = EMPTY;
      for (int j0=1; j0<gridH; j0++)
        for (int i0=0; i0<gridW; i0++)
          if (grid[j0][i0]<4*maxElemTypes) 
            eat(i0, j0);
    }  else if (aT==DOUBLELASER) {
      int other = grid[animj][animi];
      int target = grid[animj2][animi2];

      int toCrush = 0;
      int crushi=-1;
      int crushj=-1;
      for (int j0=1; j0<gridH; j0++)
        for (int i0=0; i0<gridW; i0++){
          if (grid[j0][i0]%maxElemTypes != target%maxElemTypes && grid[j0][i0]<2*maxElemTypes){
            if (toCrush==0){
              crushi = i0;
              crushj = j0;
            }
            toCrush++;
          }
        }
      
     grid[animj2][animi2] = EMPTY; //enleve le sachet
     for (int j0=1; j0<gridH; j0++)
        for (int i0=0; i0<gridW; i0++){
          if (grid[j0][i0]%maxElemTypes == target%maxElemTypes &&  (j0!=animj || i0!=animi) && (j0!=crushj || i0!=crushi) && grid[j0][i0]<4*maxElemTypes)
            eat(i0, j0);
        }
        
      animType    = LASER;
      animi2      = crushi;
      animj2      = crushj;
      animRunning = true;
      animCount   = 20;
      loop();
    } else if (aT==ALLSTRIP) {
      int other = grid[animj2][animi2];
      grid[animj][animi] = EMPTY;
      int toCrush = 0;
      int crushi=-1;
      int crushj=-1;
      for (int j0=1; j0<gridH; j0++)
        for (int i0=0; i0<gridW; i0++){
          if (grid[j0][i0]%maxElemTypes == other%maxElemTypes && grid[j0][i0]<2*maxElemTypes){
            if (random(0,2)<=1)
              grid[j0][i0] = (grid[j0][i0]%maxElemTypes)+2*maxElemTypes; // rend le bonbon raye
            else 
              grid[j0][i0] = (grid[j0][i0]%maxElemTypes)+maxElemTypes; // rend le bonbon raye
            if (toCrush==0){
              crushi = i0;
              crushj = j0;
            }
            toCrush++;
          }
        }
      if(toCrush>0) {
        if (grid[crushj][crushi]>=maxElemTypes && grid[crushj][crushi]<2*maxElemTypes)
          animType= ALLSTRIP2;
        else
          animType= ALLSTRIP3;
        animi = crushi;
        animj = crushj;
        animRunning = true;
        animCount   = 20;
        loop();
      }
    } else if (aT==ALLSTRIP3) {
      animRunning = true;
      for (int j0=1; j0<gridH; j0++){
        if (j0!=animj) eat(animi, j0);
      }

      int toCrush = 0;
      int crushi=-1;
      int crushj=-1;
      for (int j0=1; j0<gridH; j0++)
        for (int i0=0; i0<gridW; i0++){
          if (grid[j0][i0]%maxElemTypes == grid[animj][animi]%maxElemTypes && 
              (j0!=animj||i0!=animi) && estRaye(i0,j0) && !emptyOrFalling(i0,j0)){
            if (toCrush==0){
              crushi = i0;
              crushj = j0;
            }
            toCrush++;
          }
        }
      grid[animj][animi] = EMPTY;
      if(toCrush>0) {
        if (grid[crushj][crushi]>=maxElemTypes && grid[crushj][crushi]<2*maxElemTypes)
          animType= ALLSTRIP2;
        else
          animType= ALLSTRIP3;
        animi = crushi;
        animj = crushj;
        animRunning = true;
        animCount   = 20;
        loop();
      }
      else {
        animRunning = false;
      }
      
    } else if (aT==ALLSTRIP2) {
      animRunning = true;
      for (int i0=0; i0<gridW; i0++){
        if (i0!=animi) eat(i0, animj);
      }
      int toCrush = 0;
      int crushi=-1;
      int crushj=-1;
      for (int j0=1; j0<gridH; j0++)
        for (int i0=0; i0<gridW; i0++){
          if (grid[j0][i0]%maxElemTypes == grid[animj][animi]%maxElemTypes && 
              (j0!=animj||i0!=animi) && estRaye(i0,j0)  && !emptyOrFalling(i0,j0)){
            if (toCrush==0){
              crushi = i0;
              crushj = j0;
            }
            toCrush++;
          }
        }
      grid[animj][animi] = EMPTY;
      if(toCrush>0) {
        if (grid[crushj][crushi]>=maxElemTypes && grid[crushj][crushi]<2*maxElemTypes)
          animType= ALLSTRIP2;
        else
          animType= ALLSTRIP3;
        animi = crushi;
        animj = crushj;
        animRunning = true;
        animCount   = 20;
        loop();
      } else {
        animRunning = false;
      }
      
    }
    if(!animRunning) {
      animj  = -1;
      animi  = -1;   
      animj2 = -1;
      animi2 = -1;  
    }   
  }
}// stopAnim() //////////////////////////


void eat(int i, int j){
  //println("eat "+i+" "+j+" "+grid[j][i]);
  int old = grid[j][i];
  if (old==EMPTY) {
    // NOTHING
  } else if (old<maxElemTypes) {
    grid[j][i] = EMPTY;
  } else if (old<2*maxElemTypes) 
    startAnim(20, HORI, i, j, -1, -1);
  else if (old<3*maxElemTypes) 
    startAnim(20, VERT, i, j, -1, -1);
  else if (old<4*maxElemTypes) 
    startAnim(20, SQBOOM, i, j, -1, -1);
  else if (old<5*maxElemTypes) 
    startAnim(20, LASER, i, j, -1, -1);
}// eat ()///////////////////////


// en i,j dans la grille il y a des bonbons a detruire autour
// cette fonction les detuit (appel a la fonction eat) et retourne le nombre exact de bonbon detruits 
int crush(int i, int j){
  int crushed = 0;
  int type    = grid[j][i]%maxElemTypes;
  int hor     = countSame(i, j, +1, 0) + countSame(i, j, -1, 0)+1;
  int ver     = countSame(i, j, 0, +1) + countSame(i, j, 0, -1)+1;
  eat(i,j);
  int replace = EMPTY;
  
  // cas speciaux, preparation du bonbon special.
  if(hor>=5 || ver>=5)
    replace = type+4*maxElemTypes; // meme type mais en boule choco
  else if(hor>=3 && ver>=3)
    replace = type+3*maxElemTypes; // meme type mais en sachet
  else if(hor>=4)
    replace = type+2*maxElemTypes; // meme type mais en raye vertical 
  else if(ver>=4)
    replace = type+1*maxElemTypes; // meme type mais en raye horizontal
  else 
    crushed++; // sera juste detruit dans la liste de 3 
    
  
  if (hor>=3){ // il faut detruire les bonbons sur l'horizontale
    int i0=i-1;
    while (i0>=0 && grid[j][i0]>=0 && grid[j][i0]%maxElemTypes==type && grid[j][i0]<4*maxElemTypes)    {eat(i0, j); i0--;crushed++;}
    i0=i+1;
    while (i0<gridW && grid[j][i0]>=0 && grid[j][i0]%maxElemTypes==type && grid[j][i0]<4*maxElemTypes) {eat(i0, j); i0++;crushed++;}
  }
  if (ver>=3){ // il faut detruire les bonbons sur la verticale
    int j0=j-1;
    while (j0>=0 && grid[j0][i]>=0 && grid[j0][i]%maxElemTypes==type && grid[j0][i]<4*maxElemTypes)    {eat(i, j0); j0--;crushed++;}
    j0=j+1;
    while (j0<gridH && grid[j0][i]>=0 && grid[j0][i]%maxElemTypes==type && grid[j0][i]<4*maxElemTypes) {eat(i, j0); j0++;crushed++;}
  }
  
  // remplacement du bonbon qui a initie la destruction par un eventuel bonbon special
  // remplacement du bonbon qui a initie la destruction par un eventuel bonbon special
  // sauf si c'est lui meme un bonbon special ... auquel cas il faudrait mettre le bonbon special
  // cree au hasard a cote.
  if (i==animi && j==animj){
    //TODO: deplacer le bonbon special si il y a lieu
  } else
    grid[j][i] = replace;
  return crushed;
}// crush()


void draw(){
  // T2.7 ... au lieu d'une couleur unie.
  
  // @pjs preload must be used to preload the image
  
  /* @pjs preload="laDefense.jpg"; */
  
  background(bg);
 
  imageMode(CORNER);
  stroke(0, 0, 0, 10);
  textAlign(CENTER, CENTER);
  textSize(14); 
  
  int moving = 0;
  int crushed = 0;
  int created = 0;

  // dessin de la grille
  // T2.1
 
   for(int j=0; j<gridH; j++){   
    for(int i=0; i<gridW; i++){
      image(dst,leftMargin+i*cellWidth,topMargin+j*cellHeight);
    }
  }
  imageMode(CENTER);
  for(int j=0; j<gridH; j++)
    line (leftMargin, topMargin+j*cellHeight, width, topMargin+j*cellHeight);
  for(int i=0; i<gridW; i++)
    line (leftMargin+i*cellWidth, topMargin, leftMargin+i*cellWidth, height);
  
  // mouvement des bonbons 
  for(int j=gridH-1; j>=0; j--)
    for(int i=0; i<gridW; i++){
      int rawtype = grid[j][i];
      if (rawtype>=0) {
        int type = grid[j][i]%maxElemTypes;
        int bonus = floor((grid[j][i]-type)/maxBonusTypes);
        float dx = gridDec[j][i]%cellWidth;
        float dy = gridDec[j][i]/cellWidth;
        if (dy>0 && dy<cellHeight && j<gridH-1 && emptyOrFalling(i, j+1) ) { // ca tombe !
        gridDec[j][i]*=2; //T2.6    modified 1
        moving++;
         
        }
      }
    }
    
    // on teste les bonbons qui tombent et si ils depassent un deplacement d'une case, on
    // les place effectivement une case plus bas ... et soit ils contnuent leur chute soit ils 
    // se posent et font eventuellement des combinaisons 
    for(int j=gridH-1; j>=0; j--)
      for(int i=0; i<gridW; i++){
        int rawtype = grid[j][i];
        if (rawtype>=0) {
          int dx = gridDec[j][i]%cellWidth;
          int dy = gridDec[j][i]/cellWidth;
          if (dy >= cellHeight){
            grid[j+1][i]    =  grid[j][i];
            grid[j][i]      =  EMPTY;
            gridDec[j][i]   =  0;
            gridDec[j+1][i] =  0;  
            
            if (crushable(i, j+1) && (j+1==gridH-1 || !emptyOrFalling(i, j+2))){
              crushed += crush(i, j+1);
            }
            if (grid[j][i]==-1 && j==0){
              created ++;
              do {
                grid[j][i] = int(random(0, maxAvailTypes));
              } while (crushable(i, j));
            }
            if (emptyOrFalling(i, j+1)){
              gridDec[j+1][i] = cellWidth*32; 
              if (grid[j][i]!=-1)
                gridDec[j][i] = cellWidth*32; 
            } else if(grid[j][i]!=-1){
              if(crushable(i, j)) {
                crushed += crush(i, j);
              }
            }
          }
        }
      }
  
  // dessin des bonbons
  for(int j=gridH-1; j>=0; j--)
    for(int i=0; i<gridW; i++){
      int rawtype = grid[j][i];
      if (rawtype>=0) {
        int type = grid[j][i]%maxElemTypes;
        int bonus = (grid[j][i]-type)/maxBonusTypes;
        float dx = gridDec[j][i]%cellWidth;
        float dy = gridDec[j][i]/cellWidth;
        
        //if (dy>0)
        //  dx += 0.5*(3*noise(i+frameCount, j+frameCount));
        
        // decalle le bonbon vers son voisin (et vice versa) pour montrer la permutation en cours
        if (i==cellCX && j==cellCY && abs(cellCX-cellDX)+abs(cellCY-cellDY)==1){
          dx = int((cellDX-cellCX)*cellWidth*propAnim);
          dy = int((cellDY-cellCY)*cellHeight*propAnim);
        } else if (i==cellDX && j==cellDY && abs(cellCX-cellDX)+abs(cellCY-cellDY)==1){
          dx = int((cellCX-cellDX)*cellWidth*propAnim);
          dy = int((cellCY-cellDY)*cellHeight*propAnim);
        }

        // T3.4
        if ((animType==SQBOOM && i>=animi-1 && i<=animi+1 && j>=animj-1 && j<=animj+1)||
            (animType==SQDBLBOOM && i>=animi-2 && i<=animi+2 && j>=animj-2 && j<=animj+2)){
          pushMatrix();
          translate(leftMargin+i*cellWidth+cellWidth/2+dx, topMargin+j*cellHeight+cellHeight/2+dy);
          scale(1.5-abs(animCount/10.0-1.5));
          image(imgs[bonus+1][type], 0, 0);
          popMatrix();
        } else {
          if (bonus==6) println("GLOUPS "+i+","+j+" => "+grid[j][i]);
          image(imgs[bonus+1][type], leftMargin+i*cellWidth+cellWidth/2+dx, topMargin+j*cellHeight+cellHeight/2+dy); 
        }
        //fill(0);
        //text(rawtype,              leftMargin+i*cellWidth+cellWidth/2+dx, topMargin+j*cellHeight+cellHeight/2+dy);
        //text(i+","+j,              leftMargin+i*cellWidth+cellWidth/2+dx, 15+topMargin+j*cellHeight+cellHeight/2+dy); 
        //text(dx+","+dy,              leftMargin+i*cellWidth+cellWidth/2+dx, 15+topMargin+j*cellHeight+cellHeight/2+dy); 
      }
    }
    

  // dessin des animations speciales
  if (moving==0 && crushed==0 && animType==FALLING){
    stopAnim();
  }
  if (animCount==0 && animType!=NONE){
    stopAnim();
    updateGrid();
  }
  if ((animType==HORI || animType==ALLSTRIP2) && animCount>0){
    //T3.1 remplacer ce dessin de cercles 
    float starti    = leftMargin+animi*cellWidth+cellWidth/2;
    float startj    = topMargin+animj*cellHeight+cellHeight/2;
    animCount--;
    //arc(starti, startj, 80, 80, 0, 2*PI*animCount/20, PIE); // T3.1
    for (int i=-50; i<50; i++){
  fill (random(255), random(255), random(255));
  ellipse(starti+i*10, startj, 5, 5);
}

    //T3.1 remplacer ce dessin du bonbon raye 
     int type  = grid[animj][animi]%maxElemTypes;
    int bonus = grid[animj][animi]/maxBonusTypes;
    pushMatrix();
    translate( leftMargin+animi*cellWidth+cellWidth/2, topMargin+animj*cellHeight+cellHeight/2);
    scale(animCount/3.9);
    rotate(4*PI/animCount);
    image(imgs[bonus+1][type],0, 0);
    popMatrix();
  } else if ((animType==VERT || animType==ALLSTRIP3) && animCount>0){
    //T3.1 remplacer ce dessin de cercles 
    float starti    = leftMargin+animi*cellWidth+cellWidth/2;
    float startj    = topMargin+animj*cellHeight+cellHeight/2;
    animCount--;
    arc(starti, startj, 80, 80, 0, 2*PI*animCount/20, PIE); //T3.1
    
    //T3.1 remplacer ce dessin du bonbon raye 
    int type  = grid[animj][animi]%maxElemTypes;
    int bonus = grid[animj][animi]/maxBonusTypes;
    pushMatrix();
    translate( leftMargin+animi*cellWidth+cellWidth/2, topMargin+animj*cellHeight+cellHeight/2);
    scale(animCount/3.9);
    rotate(4*PI/animCount);
    image(imgs[bonus+1][type],0, 0);
    popMatrix();
    
  } else if ((animType==LASER || animType==DOUBLELASER) && animCount>0){
    int starti    = leftMargin+animi*cellWidth+cellWidth/2;
    int startj    = topMargin+animj*cellHeight+cellHeight/2;
    int typeLaser = grid[animj2][animi2]%maxElemTypes;
    animCount--;
    // T3.4
    stroke(255, 255, 128, 255);
    strokeWeight(3);
    for (int j0=0; j0<gridH; j0++)
      for (int i0=0; i0<gridW; i0++){
        if (grid[j0][i0]%maxElemTypes == typeLaser && grid[j0][i0]<4*maxElemTypes) {
          int endi    = leftMargin+i0*cellWidth+cellWidth/2;
          int endj    = topMargin+j0*cellHeight+cellHeight/2;
          
          line(starti+(min(20, 30-animCount))*(endi-starti)/20, startj+(min(20, 30-animCount))*(endj-startj)/20, 
               starti+(max(0, 15-animCount))*(endi-starti)/20,   startj+(max(0, 15-animCount))*(endj-startj)/20);
        } 
      }
    strokeWeight(1);
  } else if (animType==SUPERLASER && animCount>0){
    int starti    = leftMargin+animi*cellWidth+cellWidth/2;
    int startj    = topMargin+animj*cellHeight+cellHeight/2;
    animCount--;
    int i0 = animCount%gridW;
    int j0 = floor(animCount/gridW);
    stroke(255, 255, 128, 255);
    strokeWeight(3);
   
    println(i0+","+j0);
    if (j0>0 && grid[j0][i0]<4*maxElemTypes) {
      int endi    = leftMargin+i0*cellWidth+cellWidth/2;
      int endj    = topMargin+j0*cellHeight+cellHeight/2;
      
      line(starti, startj, endi, endj);
    } 
    strokeWeight(1);
  } else if (animType==ALLSTRIP && animCount>0){
    int starti    = leftMargin+animi*cellWidth+cellWidth/2;
    int startj    = topMargin+animj*cellHeight+cellHeight/2;
    int typeLaser = grid[animj2][animi2]%maxElemTypes;
    animCount--;
    
    stroke(255, 255, 128, 255);
    strokeWeight(3);
    for (int j0=0; j0<gridH; j0++)
      for (int i0=0; i0<gridW; i0++){
        if (grid[j0][i0]%maxElemTypes == typeLaser && grid[j0][i0]<4*maxElemTypes) {
          int endi    = leftMargin+i0*cellWidth+cellWidth/2;
          int endj    = topMargin+j0*cellHeight+cellHeight/2;
          
          line(starti+(min(20, 30-animCount))*(endi-starti)/20, startj+(min(20, 30-animCount))*(endj-startj)/20, 
               starti+(max(0, 15-animCount))*(endi-starti)/20,   startj+(max(0, 15-animCount))*(endj-startj)/20);
        } 
      }
    strokeWeight(1);
  } else if (animType==SQBOOM || animType==SQDBLBOOM ){
    animCount--;// T3.4
  } else if (animType==STARCROSS) {
    float starti    = leftMargin+animi*cellWidth+cellWidth/2;
    float startj    = topMargin+animj*cellHeight+cellHeight/2;
    animCount--;// T3.4
    for (int k=0; k<25; k++) {
      stroke(255, 255, 128, 255);
      float endi    = starti;
      float endj    = startj+(20-animCount)*max(startj, height-startj)/20+random(0, 10);
      float ri = random(-cellWidth/2, cellWidth/2); 
      
      line(starti+ri, startj, endi+ri, endj);
      endj    = startj-(20-animCount)*max(startj, height-startj)/20-random(0, 10);
      line(starti+ri, startj, endi+ri, endj);
    }
    for (int k=0; k<25; k++) {
      stroke(255, 255, 128, 255);
      float endi    = starti+(20-animCount)*max(starti, width-starti)/20+random(0, 10);
      float endj    = startj;
      float rj = random(-cellHeight/2, cellHeight/2); 
      line(starti, startj+rj, endi, endj+rj);
      endi    = starti-(20-animCount)*max(starti, width-starti)/20-random(0, 10);
      line(starti, startj+rj, endi, endj+rj);
    }
    int type  = grid[animj][animi]%maxElemTypes;
    int bonus = grid[animj][animi]/maxBonusTypes;
    pushMatrix();
    translate( leftMargin+animi*cellWidth+cellWidth/2, topMargin+animj*cellHeight+cellHeight/2);
    scale(1, (10-animCount));
    tint(255, 255, 255, 55+animCount*10);
    image(imgs[bonus+1][type],0, 0);
    noTint();
    popMatrix();
    pushMatrix();
    translate( leftMargin+animi*cellWidth+cellWidth/2, topMargin+animj*cellHeight+cellHeight/2);
    scale((10-animCount), 1);
    tint(255, 255, 255, 55+animCount*10);
    image(imgs[bonus+1][type],0, 0);
    noTint();
    popMatrix();
  } else if (animType==BIGBONBON){
    float starti    = leftMargin+animi*cellWidth+cellWidth/2;
    float startj    = topMargin+animj*cellHeight+cellHeight/2;
    animCount--;
    for (int k=0; k<25; k++) {
      stroke(255, 255, 128, 255);
      float endi    = starti;
      float endj    = startj+(20-animCount)*max(startj, height-startj)/20+random(0, 10);
      float ri = random(-3*cellWidth/2, 3*cellWidth/2); 
      
      line(starti+ri, startj, endi+ri, endj);
      endj    = startj-(20-animCount)*max(startj, height-startj)/20-random(0, 10);
      line(starti+ri, startj, endi+ri, endj);
    }
    for (int k=0; k<25; k++) {
      stroke(255, 255, 128, 255);
      float endi    = starti+(20-animCount)*max(starti, width-starti)/20+random(0, 10);
      float endj    = startj;
      float rj = random(-3*cellHeight/2, 3*cellHeight/2); 
      line(starti, startj+rj, endi, endj+rj);
      endi    = starti-(20-animCount)*max(starti, width-starti)/20-random(0, 10);
      line(starti, startj+rj, endi, endj+rj);
    }
    int type  = grid[animj][animi]%maxElemTypes;
    int bonus = grid[animj][animi]/maxBonusTypes;
    pushMatrix();
    translate( leftMargin+animi*cellWidth+cellWidth/2, topMargin+animj*cellHeight+cellHeight/2);
    scale(3, (10-animCount));
    tint(255, 255, 255, 55+animCount*10);
    //println(animi+","+animj+""+grid[animj][animi]+"=>"+bonus+" "+type);
    image(imgs[bonus+1][type],0, 0);
    noTint();
    popMatrix();
    pushMatrix();
    translate( leftMargin+animi*cellWidth+cellWidth/2, topMargin+animj*cellHeight+cellHeight/2);
    scale((10-animCount), 3);
    tint(255, 255, 255, 55+animCount*10);
    image(imgs[bonus+1][type],0, 0);
    noTint();
    popMatrix();
  }
  
  // T3.2
  
  // T3.3
  
  if (crushed>0) updateGrid();
  if (created>0 && !animRunning) redraw();
}// draw()


void mousePressed(){
  cellCX = (mouseX-leftMargin)/cellWidth;
  cellCY = (mouseY-topMargin)/cellHeight;
  if (cellCX<0 || cellCX>=gridW || cellCY<0 || cellCY>=gridH || animRunning){
    cellCX = -1;
    cellCY = -1;
  }
}


void mouseDragged(){
  cellDX = (mouseX-leftMargin)/cellWidth;
  cellDY = (mouseY-topMargin)/cellHeight;
  float prevPropAnim=propAnim;
  propAnim=0.0;
  if (cellCX>=0 && cellCY>=0 && cellDX>=0 && cellDX<gridW && cellDY>=0 && cellDY<gridH && 
      grid[cellCY][cellCX]>=0 && grid[cellDY][cellDX]>=0) {
    if (cellDX!=cellCX)
      propAnim = min(1.0, abs((mouseX-float(cellCX*cellWidth+leftMargin+cellWidth/2))/cellWidth));
    else
      propAnim = min(1.0, abs((mouseY-float(cellCY*cellHeight+topMargin+cellHeight/2))/cellHeight));
    if (propAnim>0.0 && propAnim!=prevPropAnim) {
      redraw();
    }
  }
}


void mouseReleased() {
  //println("MR "+cellCX+","+cellCY);
  cellDX = -1;
  cellDY = -1;
  int cellRX = (mouseX-leftMargin)/cellWidth;
  int cellRY = (mouseY-topMargin)/cellHeight;
  if (cellCX>=0 && cellCX<gridW && cellCY>=0 && cellCY<gridH && 
      cellRX>=0 && cellRX<gridW && cellRY>=0 && cellRY<gridH){
    if (abs(cellRX-cellCX)+abs(cellRY-cellCY)==1 ){
      int tmp = grid[cellCY][cellCX];
      grid[cellCY][cellCX]=grid[cellRY][cellRX];
      grid[cellRY][cellRX]=tmp;
      //println("in "+cellCX+", "+cellCY+" there is now "+grid[cellCY][cellCX]);
      //println("in "+cellRX+", "+cellRY+" there is now "+grid[cellRY][cellRX]);
      int crushed = 0;
      
      // Boule en chocolat jetee sur un bonbon simple
      if (grid[cellRY][cellRX]>=4*maxElemTypes && grid[cellCY][cellCX]<maxElemTypes && grid[cellCY][cellCX]!=EMPTY){
        startAnim(20, LASER, cellRX, cellRY, cellCX, cellCY);
        return;
      } else if (grid[cellCY][cellCX]>=4*maxElemTypes && grid[cellRY][cellRX]<maxElemTypes && grid[cellRY][cellRX]!=EMPTY){
        startAnim(20, LASER, cellCX, cellCY,  cellRX, cellRY);
        return;
      }

      // deux boules en chocolat l'une sur l'autre
      if (grid[cellRY][cellRX]>=4*maxElemTypes && grid[cellCY][cellCX]>=4*maxElemTypes){
        startAnim(gridW*gridH, SUPERLASER, cellRX, cellRY, cellCX, cellCY);
        println("SL");
        return;
      }
      
      // une boule en chocolat sur un sachet
      if (grid[cellRY][cellRX]>=4*maxElemTypes && grid[cellCY][cellCX]>=3*maxElemTypes && grid[cellCY][cellCX]<4*maxElemTypes){
        startAnim(20, DOUBLELASER, cellRX, cellRY, cellCX, cellCY);
        return;
      } else if (grid[cellRY][cellRX]>=3*maxElemTypes && grid[cellCY][cellCX]>=4*maxElemTypes && grid[cellRY][cellRX]<4*maxElemTypes){
        startAnim(20, DOUBLELASER, cellCX, cellCY, cellRX, cellRY);
        return;
      }
      
      // une boule en chocolat sur un bonbon raye
      if (grid[cellRY][cellRX]>=4*maxElemTypes && grid[cellCY][cellCX]>=2*maxElemTypes && grid[cellCY][cellCX]<3*maxElemTypes){
        startAnim(20, ALLSTRIP, cellRX, cellRY, cellCX, cellCY);
        return;
      } else if (grid[cellRY][cellRX]>=2*maxElemTypes && grid[cellCY][cellCX]>=4*maxElemTypes && grid[cellRY][cellRX]<3*maxElemTypes){
        startAnim(20, ALLSTRIP, cellCX, cellCY, cellRX, cellRY);
        return;
      }

      
      // sachet sur sachet
      if (grid[cellRY][cellRX]>=3*maxElemTypes && grid[cellRY][cellRX]<4*maxElemTypes && grid[cellCY][cellCX]>=3*maxElemTypes && grid[cellCY][cellCX]<4*maxElemTypes){
        startAnim(20, SQDBLBOOM, cellRX, cellRY, -1, -1);
        //grid[cellRY][cellRX] = EMPTY;
        //grid[cellCY][cellCX] = EMPTY;
        return;
      }
      
      // raye sur raye
      if (grid[cellRY][cellRX]>=1*maxElemTypes && grid[cellRY][cellRX]<3*maxElemTypes && grid[cellCY][cellCX]>=1*maxElemTypes && grid[cellCY][cellCX]<3*maxElemTypes){
        startAnim(20, STARCROSS, cellRX, cellRY, -1, -1);
        //grid[cellRY][cellRX] = EMPTY;
        //grid[cellCY][cellCX] = EMPTY;
        return;
      }
      // raye sur sachet ou vice-versa
      if ((grid[cellRY][cellRX]>=1*maxElemTypes && grid[cellRY][cellRX]<3*maxElemTypes && grid[cellCY][cellCX]>=3*maxElemTypes && grid[cellCY][cellCX]<4*maxElemTypes) ||
          (grid[cellRY][cellRX]>=3*maxElemTypes && grid[cellRY][cellRX]<4*maxElemTypes && grid[cellCY][cellCX]>=1*maxElemTypes && grid[cellCY][cellCX]<3*maxElemTypes)){
        startAnim(20, BIGBONBON, cellRX, cellRY, cellCX, cellCY);
        //grid[cellRY][cellRX] = EMPTY;
        //grid[cellCY][cellCX] = EMPTY;
        return;
      }
      
      // coup normal
      else {
        if(crushable(cellCX, cellCY))
          crushed += crush(cellCX, cellCY);
        if(crushable(cellRX, cellRY))
          crushed += crush(cellRX, cellRY);
        if (crushed>0) {
          updateGrid();
        } else {
          // le coup etait interdit car il ne detruit rien !
          tmp = grid[cellCY][cellCX];
          grid[cellCY][cellCX]=grid[cellRY][cellRX];
          grid[cellRY][cellRX]=tmp;
        }
      }
    }    
  }
  redraw();
}