package com.hospital;

import java.io.FileWriter;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Scanner;

public class App {

    // Connection Config (Matches your Docker setup)
    private static final String URL = "jdbc:mysql://127.0.0.1:3306/hospital_management_system?useSSL=false&allowPublicKeyRetrieval=true";
    private static final String USER = "hospital_guest";
    private static final String PASS = "1234";

    public static void main(String[] args) {
        System.out.println("--- Hospital Data Exporter ---");

        try (Scanner scanner = new Scanner(System.in)) {
            // 1. Ask for Patient ID (SSN)
            System.out.print("Enter Patient SSN to export: ");
            String ssnInput = scanner.nextLine();

            // Basic validation
            if (!ssnInput.matches("\\d+")) {
                System.err.println("Error: SSN must be a number.");
                return;
            }
            int patientSSN = Integer.parseInt(ssnInput);

            // 2. Connect to Database
            try (Connection conn = DriverManager.getConnection(URL, USER, PASS)) {
                System.out.println("Connected to Database successfully!");

                // 3. Run Exports
                boolean foundData = exportToCSV(conn, patientSSN);

                if (foundData) {
                    exportToXML(conn, patientSSN);
                    System.out.println("\nDone! Check your project folder for the files.");
                } else {
                    System.out.println("No records found for Patient SSN: " + patientSSN);
                }

            } catch (Exception e) {
                System.err.println("Database Error: " + e.getMessage());
                e.printStackTrace();
            }

        }
    }

    // ---------------------------------------------------
    // EXPORT TO CSV
    // ---------------------------------------------------
    private static boolean exportToCSV(Connection conn, int ssn) {
        // We use the new "Patient SSN" column you added to the View
        String sql = "SELECT * FROM view_prescribed_medications WHERE `Patient SSN` = ?";
        boolean hasData = false;

        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, ssn);
            ResultSet rs = stmt.executeQuery();

            // Create CSV File
            String fileName = "patient_" + ssn + ".csv";
            try (PrintWriter writer = new PrintWriter(new FileWriter(fileName))) {
                // Write Header
                writer.println("Medication Code,Medication Name,Brand,Patient Name,Date,Doctor Name");

                // Write Rows
                while (rs.next()) {
                    hasData = true;
                    writer.printf("%d,\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"%n",
                            rs.getInt("Medication Code"),
                            rs.getString("Medication Name"),
                            rs.getString("Brand"),
                            rs.getString("Patient Name"),
                            rs.getString("Date"),
                            rs.getString("Doctor Name"));
                }
            }

            if (hasData) {
                System.out.println("-> CSV Generated: " + fileName);
            }

        } catch (Exception e) {
            System.err.println("CSV Export Failed: " + e.getMessage());
        }
        return hasData;
    }

    // ---------------------------------------------------
    // EXPORT TO XML
    // ---------------------------------------------------
    private static void exportToXML(Connection conn, int ssn) {
        String sql = "SELECT * FROM view_prescribed_medications WHERE `Patient SSN` = ?";

        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, ssn);
            ResultSet rs = stmt.executeQuery();

            String fileName = "patient_" + ssn + ".xml";
            try (PrintWriter writer = new PrintWriter(new FileWriter(fileName))) {

                // Write XML Header and Root Element
                writer.println("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
                writer.println("<patient_medications ssn=\"" + ssn + "\">");

                while (rs.next()) {
                    writer.println("\t<prescription>");
                    writeXmlElement(writer, "med_code", String.valueOf(rs.getInt("Medication Code")));
                    writeXmlElement(writer, "med_name", rs.getString("Medication Name"));
                    writeXmlElement(writer, "brand", rs.getString("Brand"));
                    writeXmlElement(writer, "patient_name", rs.getString("Patient Name"));
                    writeXmlElement(writer, "date", rs.getString("Date"));
                    writeXmlElement(writer, "doctor_name", rs.getString("Doctor Name"));
                    writer.println("\t</prescription>");
                }

                // Close Root Element
                writer.println("</patient_medications>");
            }
            System.out.println("-> XML Generated: " + fileName);

        } catch (Exception e) {
            System.err.println("XML Export Failed: " + e.getMessage());
        }
    }

    // Helper to write XML tags safely
    private static void writeXmlElement(PrintWriter writer, String tag, String value) {
        if (value == null)
            value = "";
        // Basic escape for XML special characters
        value = value.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&apos;");

        writer.println("\t\t<" + tag + ">" + value + "</" + tag + ">");
    }
}