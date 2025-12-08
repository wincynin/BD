import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVPrinter;

import java.io.FileWriter;
import java.io.IOException;

public class WriteCsv {

    private static final String AGENDA_CSV = "./src/main/resources/agenda.csv";

    public static void main (String [] args) throws IOException {

        // Abre el fichero CSV en modo escritura. El segundo parametro (append) nos indica si queremos añadir datos
        // a un fichero ya existente (append=true) o si queremos sobre-escribir todos los datos (append=false)

        FileWriter writer = new FileWriter(AGENDA_CSV, false);


        // Instancia un nuevo objeto CSVPrinter que gestiona la creación de ficheros CSV

        CSVPrinter csvPrinter = new CSVPrinter(writer, CSVFormat.DEFAULT);


        // Imprime la cabecera del fichero

        csvPrinter.printRecord("nombre", "apellidos", "telefono", "direccion");


        // @TODO: añade tres resgistros al fichero CSV usando csvPrinter.printRecord teniendo en cuenta los datos
        // declarados en la cabecera del fichero



        // Cerramos el fichero

        csvPrinter.close();
        writer.close();
    }
}
