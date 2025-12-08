import datamodel.Capitulo;
import datamodel.Serie;
import datamodel.Usuario;
import org.hibernate.Session;
import org.hibernate.SessionFactory;
import org.hibernate.boot.MetadataSources;
import org.hibernate.boot.registry.StandardServiceRegistry;
import org.hibernate.boot.registry.StandardServiceRegistryBuilder;

import javax.persistence.Query;
import java.util.List;

public class Main {

    public static void main (String [] args) throws Exception {

        // Creación de la factoría

        StandardServiceRegistry registry = new StandardServiceRegistryBuilder()
                .configure()
                .build();

        SessionFactory sessionFactory = new MetadataSources(registry)
                .buildMetadata()
                .buildSessionFactory();

        Session session = sessionFactory.openSession();

        // Creación de la serie lost

        Serie lost = new Serie("Lost", "SciFi");

        Capitulo lost1x01 = new Capitulo("Pilot, Part1", 42, lost);
        Capitulo lost1x02 = new Capitulo("Pilot, Part2", 41, lost);

        lost.getCapitulos().add(lost1x01);
        lost.getCapitulos().add(lost1x02);

        session.beginTransaction();
        session.saveOrUpdate(lost);
        session.getTransaction().commit();


        // Actualización de la serie lost

        lost.setGenero("Sci-Fi");

        session.beginTransaction();
        session.saveOrUpdate(lost);
        session.getTransaction().commit();


        // Creación de la serie Friends

        Serie friends = new Serie ("Friends", "Comedia");

        Capitulo friends1x01 = new Capitulo("The Pilot", 21, friends);
        friends.getCapitulos().add(friends1x01);

        session.beginTransaction();
        session.saveOrUpdate(friends);
        session.getTransaction().commit();


        // Creación de dos usuarios

        Usuario alice = new Usuario("Alice");

        alice.getCapitulos().add(lost1x01);
        lost1x01.getUsuarios().add(alice);

        alice.getCapitulos().add(friends1x01);
        friends1x01.getUsuarios().add(alice);


        Usuario bob = new Usuario("Bob");

        bob.getCapitulos().add(friends1x01);
        friends1x01.getUsuarios().add(bob);


        session.beginTransaction();
        session.saveOrUpdate(alice);
        session.saveOrUpdate(bob);
        session.getTransaction().commit();


        // Consultamos todas las series de genero "Sci-fi"

        Query query = session.createQuery("from Serie where genero = :genero");
        query.setParameter("genero", "Sci-Fi");
        List <Serie> list = query.getResultList();

        for (Serie ser : list) {
            System.out.println(ser.getTitulo());
        }

        session.close();
    }
}

