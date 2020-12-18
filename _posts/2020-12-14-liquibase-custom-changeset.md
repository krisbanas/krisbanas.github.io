---
layout: post
title: "Using Spring Boot configuration in Liquibase custom change"
categories: java
---

## Introduction

> Disclaimer: I assume you are **not** using [liquibase plugin for your build tool](https://docs.liquibase.com/tools-integrations/springboot/using-springboot-with-maven.html) (like `liquibase-maven-plugin`). The solution assumes the `liquibase-core` dependency is used.

Liquibase offers a wide variety of pre-defined changesets but sometimes the desired logic of a changeset cannot be expressed within their limitations. In such scenarios, a custom change can be implemented as Java code. 

Oftentimes, when developing Spring Boot applications, we would like to allow for external configuration of the logic. For example, instead of hardcoding specific values, refer to the `application.yaml`. This is where a common issue occurs:

> The code executed during Liquibase migrations is **not** managed by Spring's `ApplicationContext`.

The common questions are: 
1. *How can I pass the parameters from application config to the Java code executed as a Liquibase changeset?* 
1. *How can I specify the behaviour of the migration if no parameter is defined?*

Let us look at the solution and follow an example.

## The Solution

All properties under `spring.liquibase` in the application config are passed to Liquibase. A handy list of available properties can be found in the [Spring Boot docs](https://docs.spring.io/spring-boot/docs/current/reference/html/appendix-application-properties.html#common-application-properties-data-migration).

The interesting part is the key [spring.liquibase.parameters.*](https://docs.spring.io/spring-boot/docs/current/reference/html/appendix-application-properties.html#spring.liquibase.parameters). It allows for creating a key:value map of parameters injectable to changesets. 

Example:

```yaml
# in application.yaml
spring:
  liquibase:
    parameters:
      param1: foo
      param2: bar
```

The values of `param1` and `param2` can be environment-specific and be injected to the `application.yaml` during deployment for example by the CD pipeline. The parameters can also be passed from the command line like any other Spring Boot property.

On the liquibase changeset's side we can now refer to the parameter in a changeset.

```xml
<changeSet id="42" author="honk">
  <customChange 
    class="name.of.package.CustomChangeExample" 
    configurableValue=${param1}/>
 </changeSet>
 ```

The value of token `${param1}` will be looked up and changed to `foo`. Now, in order to "capture" it on the Java class' side, we need a field with getter and setter. Keep in mind that the Java class has to extend `CustomTaskChange`.

> Not creating the getter and setter for `configurableValue` will not allow for parameter injection and result in `null`.

```java
package name.of.package;

public class CustomChangeExample implements CustomTaskChange {
  
  private String configurableValue;

  public String getConfigurableValue() {
    return configurableValue;
  }

  public void setConfigurableValue(String configurableValue) {
    this.configurableValue = configurableValue;
  }

  @Override
  public void execute(Database database) throws CustomChangeException {
      // configurableValue is available here
  } 

  // Other from CustomTaskChange interface below
  ...
  
}
```

There is a caveat to this approach. If the parameter is not defined in the config, Liquibase will fail to substitute the `${param1}`. In such a scenario there are two approaches.

#### Approach 1: Handling in code

If there are specific conditions, upon which the property may remain undefined and changeset should successfully pass anyway, the check can be performed in the code. 

The method `execute(Database database)` can begin by running a set of queries on the database to check if it's okay to proceed with no parameter defined.

#### Approach 2: Precondition check

If failing the migration is the desired behaviour, a [precondition](https://docs.liquibase.com/concepts/preconditions.html) check can be used to ensure the existence of the parameter. Example:

```
<preConditions>
  <changeLogPropertyDefined property="param1"/>  
</preConditions>  
```

By default, if no property is found, the changeset will fail. The behaviour can be fine-tuned to skip the changeset once or forever.

## Example

Consider a table for a `Car` entity. The entity consists of the following:
* `ID: INT NOT NULL`
* `MAKE: VARCHAR(255) NOT NULL`
* `MODEL_NAME: VARCHAR(255) NOT NULL`
* `INSURER: VARCHAR(255)`

We would like to create a `NOT NULL` constraint on the `INSURER` column and for all rows already present insert a value defined in the config with `current-insurer` key. The behaviour is:

1. If the table is **empty** (for example, a new database is created), mark changeset as done and do not require the `current-insurer` to be configured.
2. If the table is **filled**, require a `current-insurer` parameter. If the parameter is not provided, fail the migration.

Let us look into the implementation. The code example can be found [on GitHub](https://github.com/krisbanas/liquibase-example).

### 1. Create the Java class with the logic

The class has to implement the `CustomTaskChange` interface and have a `String` field for each parameter - in this case just one field `currentInsurer`.

```java
package com.github.krisbanas.migration;

// A class implementing CustomTaskChange interface
public class CustomMigrationExample implements CustomTaskChange {

  // The field that will capture the value of parameter
  private String currentInsurer;

  /*
   * Getters and setters for the currentInsurer
   */
  
  ...
}
```

All the methods of `CustomTaskChange` interface have to be implemented. Let us look at the important method `void execute(Database database)`. This is just a snippet, the entire implementation can be found on GitHub.

```java
@Override
public void execute(Database database) {
    JdbcConnection jdbcConnection = (JdbcConnection) database.getConnection();
    try {
        // If the table is empty, just skip the changeset
        if (noRowsInCarTableExist(jdbcConnection)) return;

        // Otherwise, perform the migration
        executeInsurerMigration(jdbcConnection);
    } catch (SQLException | LiquibaseException e) {
        // Arguably, the exceptions here are not recoverable as they are caused by issues with Database connectivity, permissions etc. Throwing a RuntimeException means that the changeset execution failed.
        throw new RuntimeException(e.getMessage());
    }
}

private boolean noRowsInCarTableExist(JdbcConnection jdbcConnection) throws SQLException, DatabaseException {
    try (PreparedStatement rowLookupStatement = jdbcConnection.prepareStatement(QUERY_IF_ROWS_EXIST_IN_CARS)) {
        ResultSet rs = rowLookupStatement.executeQuery();
        return !rs.next();
    }
}
```

> Always use `PreparedStatement` when invoking a plaintext SQL query with parameters. Parsing the query with tools like `String.format()` may lead to SQL injection. In our case, if someone is able to tamper with the config, they could put a malicious SQL command as a value. This command could then be inserted by the format method and executed on the database.

The SQL expressions used in the example look as follows. Depending on what database is used, the query can be optimized but this one should work on any DB. You can also use the `EXISTS` keyword.

```java
private static final String QUERY_IF_ROWS_EXIST_IN_CARS = "SELECT TOP(1) FROM CARS";

private static final String UPDATE_INSURER_ON_NULL_ENTRIES_TEMPLATE = "UPDATE CARS SET INSURER = ? WHERE INSURER IS NULL";

```

### 2. Add the parameter to changeset definition

```xml
<changeSet id="create-table" author="krisbanas">
  <customChange
    class="com.github.krisbanas.migration.CustomMigrationExample"
    currentInsurer="${current-insurer}">
  </customChange>
</changeSet>
```

The `class` should point to a fully qualified name of the Class containing implementing `CustomChangeExample`. The second entry means that the value of `current-insurer` in the configuration will be injected to `currentInsurer` field in the class.

> In the case of no `current-insurer`, the injected value will actually be `"${current-insurer}"`. It's good to check for this eventuality. In simpler use cases, a precondition can be used to ensure the existence of the value.

### 3. Add the parameter to Spring configuration

In the `application.yaml` simply put the correct value:

```yaml
spring:
  liquibase:
    parameters:
      current-insurer: Generic Insurance Group Inc.
```

Now migration should work as intended.

## Conclusion

Custom changesets give the most granular control over performed migration's logic. While the best approach is to use the built-in Liquibase changeset types, the custom Java changeset can always be used as a backup plan and is the only way to use Spring properties during the migration.


