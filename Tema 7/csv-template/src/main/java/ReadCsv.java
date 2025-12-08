import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVParser;
import org.apache.commons.csv.CSVRecord;

import java.io.IOException;
import java.io.Reader;
import java.nio.file.Files;
import java.nio.file.Paths;

public class ReadCsv {

    private static final String BARCELONA_CSV = "./src/main/resources/barcelona.csv";

    public static void main (String [] args) throws IOException {

        // Abre del fichero CSV en modo lectura

        Reader reader = Files.newBufferedReader(Paths.get(BARCELONA_CSV));


        // Define el formato del fichero CSV de acuerdo con el estándar RFC4180 que indica que:
        //
        //  - el delimitador es ,
        //  - las cadenas de caracteres se encierran entre comillas dobles "
        //  - el final de linea se representa mediante \r\n
        //  - se permite lineas vacias
        //
        // Además, se indica que el fichero contiene cabecera.

        CSVFormat format = CSVFormat.DEFAULT.withHeader();


        // Instancia un nuevo objeto de la clase CSVParser que gestiona la lectura del fichero CSV

        CSVParser csvParser = new CSVParser(reader, format);


        // La clase CSV parser implementa el interfaz Iterator que permite recorrer todos los registros de un fichero
        // CSV mediante un bucle for-each

        for (CSVRecord csvRecord : csvParser) {

            // @TODO: añade el todo el código que consideres necesario para calcular la renta media en el distrito
            //  "Gràcia" durante el año 2016
            //
            // Podrás recuperar los valores de un registro mediante:
            //
            //   csvRecord.get(<nombre_columna>)
            //
            // Ten en cuenta que el valor se devuelve como un String, por lo que deberás transformarlo al tipo de
            // datos que necesites en cada momento.

        }

        csvParser.close();
        reader.close();

    }


}
