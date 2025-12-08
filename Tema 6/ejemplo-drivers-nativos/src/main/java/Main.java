import java.sql.*;

public class Main {

    private final static String DB_SERVER = "localhost";
    private final static int DB_PORT = 3306;
    private final static String DB_NAME = "reformas";
    private final static String DB_USER = "root";
    private final static String DB_PASS = "root";

    public static void main (String [] args) throws Exception {

        // carga del driver

        Class.forName("com.mysql.cj.jdbc.Driver").newInstance();


        // conexión con la base de datos

        String url = "jdbc:mysql://" + DB_SERVER + ":" + DB_PORT + "/" + DB_NAME;
        Connection conn = DriverManager.getConnection(url, DB_USER, DB_PASS);


        // consultamos todos los conductores de arganda

        PreparedStatement stmt = conn.prepareStatement("SELECT * FROM conductores WHERE localidad = ?");
        stmt.setString(1,"Arganda");

        ResultSet rs = stmt.executeQuery();

        System.out.println("Conductores de la localidad de Arganda:");

        while(rs.next()) {
            String codC = rs.getString("codC");
            String nombre = rs.getString("nombre");
            System.out.println("(" + codC + ") " + nombre);
        }

        rs.close();
        stmt.close();


        // insertamos una nueva maquina

        stmt = conn.prepareStatement("INSERT INTO maquinas VALUE (?, ?, ?)");
        stmt.setString(1, "C10");
        stmt.setString(2, "Tuneladora");
        stmt.setInt(3, 115);

        int numRows = stmt.executeUpdate();

        System.out.println("\nSe han insertado " + numRows + " filas.");

        stmt.close();


        // listamos las maquinas

        Statement stmt2 = conn.createStatement();
        rs = stmt2.executeQuery("SELECT * FROM maquinas");

        System.out.println("\nListado de maquinas:");

        while(rs.next()) {
            String codM = rs.getString("codM");
            String nombre = rs.getString("nombre");
            int precioHora = rs.getInt("precioHora");
            System.out.println("codM = " + codM + "; nombre = " + nombre + "; precioHora = " + precioHora);
        }

        rs.close();
        stmt2.close();


        // borramos la maquina insertada

        stmt = conn.prepareStatement("DELETE FROM maquinas WHERE codM = ?");
        stmt.setString(1, "C10");

        numRows = stmt.executeUpdate();

        System.out.println("\nSe han borrado " + numRows + " filas.");

        stmt.close();


        // cierre de la conexion

        conn.close();
    }
}
