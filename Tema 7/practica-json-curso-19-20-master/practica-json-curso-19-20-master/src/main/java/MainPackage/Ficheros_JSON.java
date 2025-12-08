package MainPackage;


import com.google.gson.*;
import com.google.gson.reflect.TypeToken;

import java.io.*;
import java.util.ArrayList;
import java.util.List;



/***
 * Vamos a trabajar con el uso de ficheros de tipo .json
 * para ello utilizaremos el archivo .json y a cargar los datos mediante java
 * incluir inserciones y modificaciones sobre los datos para despues volverlos a guardar
 */
public class Ficheros_JSON {

    private static String fichero_leer = "Overwatch.json";
    private static String fichero_escribir= "Overwatch.json";

    public static void main(String[] args) {
        //Leemos los datos en formato JSON del fichero
        List <OverwatchCharacter> characters = leerJSON();

        //Mostramos los datos que hemos leido del fichero en pantalla
        mostrarPorPantalla(characters);









        //Volcamos los datos que hemos leido en el fichero
        escribirJSON(characters);
    }

    /**
     * Función para leer un archivo .JSON
     * @return devuelve una lista de objetos de tipo OverwatchCharacters
     */
    public static List <OverwatchCharacter> leerJSON(){
        try (BufferedReader reader = new BufferedReader(new FileReader(fichero_leer))){
            JsonParser parser = new JsonParser();
            JsonArray archivo_json_array = parser.parse(reader).getAsJsonArray();

            List <OverwatchCharacter> characters = new Gson().fromJson(archivo_json_array,
                    new TypeToken<ArrayList<OverwatchCharacter>>(){}.getType());

            return characters;
        } catch (IOException e) {
            e.printStackTrace();
        }
        return null;
    }

    /**
     * Función para escribir los datos de los personajes en el fichero
     * @param characters contiene una list de los personajes que se van a escribir en el fichero
     */
    public static void escribirJSON(List <OverwatchCharacter> characters){
        try (FileWriter file = new FileWriter(fichero_escribir)){
            Gson gson = new Gson();
            JsonElement element = gson.toJsonTree(characters, new TypeToken<ArrayList<OverwatchCharacter>>() {}.getType());
            JsonArray jsonArray = element.getAsJsonArray();
            file.write(jsonArray.toString());

            file.flush();
        } catch (IOException e) {
            e.printStackTrace();
        }

    }

    /**
     * Visualizamos los personajes que hay en la lista de tipo OverwatchCharacter
     * @param characters lista que contiene los objetos OverwatchCharacter
     */
    public static void mostrarPorPantalla(List <OverwatchCharacter> characters){
        for(OverwatchCharacter character: characters){
            System.out.println(character.toString());
        }
    }
}
