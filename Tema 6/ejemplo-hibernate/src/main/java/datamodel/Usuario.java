package datamodel;

import javax.persistence.*;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "usuario")
public class Usuario {

    @Id
    @GeneratedValue
    @Column(name = "id")
    private Long id;

    @Column(name = "alias", nullable = false)
    private String alias;

    @ManyToMany(cascade = CascadeType.ALL)
    @JoinTable(name = "visualizaciones")
    private Set<Capitulo> capitulos;

    public Usuario () {
        // requerido por Hibernate
    }

    public Usuario (String alias) {
        this.alias = alias;
        this.capitulos = new HashSet<Capitulo>();
    }

    public Long getId() {
        return id;
    }

    public String getAlias() {
        return alias;
    }

    public void setAlias(String alias) {
        this.alias = alias;
    }

    public Set <Capitulo> getCapitulos () {
        return this.capitulos;
    }
}
