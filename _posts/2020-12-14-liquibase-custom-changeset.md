---
layout: post
title: "Using Spring Boot configuration in Liquibase custom change"
categories: java
---

# Introduction and Problem Identification

> Disclaimer: I assume you are **not** [using liquibase plugin for your build tool](https://docs.liquibase.com/tools-integrations/springboot/using-springboot-with-maven.html) (like `liquibase-maven-plugin`). The solution assumes the `liquibase-core` dependency is used.

Liquibase offers a wide variety of pre-defined changesets but sometimes the desired logic of a changeset cannot be expressed within their limitations. In such scenarios, a custom change can be implemented as Java code. 

Oftentimes, when developing Spring Boot applications, we would like to allow for external configuration of the logic. For example, instead of hardcoding specific values, refer to the `application.yaml`. This is where a common issue occurs:

---
> The code executed during Liquibase migrations is **not** managed by Spring's `ApplicationContext`.
---

The common questions are: 
1. *How can I pass the parameters from application config to the Java code executed as a Liquibase changeset?* 
1. *How can I specify the behaviour of the migration if no parameter is defined?*

Let us look at the solution and follow an example.

# The Solution

All properties under `spring.liquibase` in the application config are made available for Liquibase. A handy list of available properties can be found in the [Spring Boot docs](https://docs.spring.io/spring-boot/docs/current/reference/html/appendix-application-properties.html#common-application-properties-data-migration).

The interesting part is the key [spring.liquibase.parameters.*](https://docs.spring.io/spring-boot/docs/current/reference/html/appendix-application-properties.html#spring.liquibase.parameters). It allows for creating a key:value map of parameters injectable to changesets. 

Example:

```
# in application.yaml
...
spring:
  liquibase:
    parameters:
      param1: foo
      param2: bar
...
```

The values of `param1` and `param2` can be environment-specific and be injected to the `application.yaml` during deployment for example by the CD pipeline. The parameters can also be passed from the command line like any other Spring Boot property.

On the liquibase changeset's side we can now refer to the parameter in a changeset.

```
<changeSet id="42" author="honk">
  <customChange 
    class="name.of.package.CustomChangeExample" 
    configurableValue=${param1}/>
 </changeSet>
 ```

The value of token `${param1}` will be looked up and changed to `foo`. Now, in order to "capture" it on the Java class' side, we need a field with getter and setter. Keep in mind that the Java class has to extend `CustomTaskChange`.

> Not creating the getter and setter for `configurableValue` will not allow for parameter injection!

```
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

  // All the methods from CustomTaskChange interface below
  .
  .
  .
  
}
```

There are two caveats to this approach:




---
## Some great heading (h2)

Proin convallis mi ac felis pharetra aliquam. Curabitur dignissim accumsan rutrum. In arcu magna, aliquet vel pretium et, molestie et arcu.

Mauris lobortis nulla et felis ullamcorper bibendum. Phasellus et hendrerit mauris. Proin eget nibh a massa vestibulum pretium. Suspendisse eu nisl a ante aliquet bibendum quis a nunc. Praesent varius interdum vehicula. Aenean risus libero, placerat at vestibulum eget, ultricies eu enim. Praesent nulla tortor, malesuada adipiscing adipiscing sollicitudin, adipiscing eget est.

## Another great heading (h2)

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce bibendum neque eget nunc mattis eu sollicitudin enim tincidunt. Vestibulum lacus tortor, ultricies id dignissim ac, bibendum in velit.

### Some great subheading (h3)

Proin convallis mi ac felis pharetra aliquam. Curabitur dignissim accumsan rutrum. In arcu magna, aliquet vel pretium et, molestie et arcu. Mauris lobortis nulla et felis ullamcorper bibendum.

Phasellus et hendrerit mauris. Proin eget nibh a massa vestibulum pretium. Suspendisse eu nisl a ante aliquet bibendum quis a nunc.

### Some great subheading (h3)

Praesent varius interdum vehicula. Aenean risus libero, placerat at vestibulum eget, ultricies eu enim. Praesent nulla tortor, malesuada adipiscing adipiscing sollicitudin, adipiscing eget est.

> This quote will *change* your life. It will reveal the <i>secrets</i> of the universe, and all the wonders of humanity. Don't <em>misuse</em> it.

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce bibendum neque eget nunc mattis eu sollicitudin enim tincidunt.

### Some great subheading (h3)

Vestibulum lacus tortor, ultricies id dignissim ac, bibendum in velit. Proin convallis mi ac felis pharetra aliquam. Curabitur dignissim accumsan rutrum.

```html
<html>
  <head>
  </head>
  <body>
    <p>Hello, World!</p>
  </body>
</html>
```


In arcu magna, aliquet vel pretium et, molestie et arcu. Mauris lobortis nulla et felis ullamcorper bibendum. Phasellus et hendrerit mauris.

#### You might want a sub-subheading (h4)

In arcu magna, aliquet vel pretium et, molestie et arcu. Mauris lobortis nulla et felis ullamcorper bibendum. Phasellus et hendrerit mauris.

In arcu magna, aliquet vel pretium et, molestie et arcu. Mauris lobortis nulla et felis ullamcorper bibendum. Phasellus et hendrerit mauris.

#### But it's probably overkill (h4)

In arcu magna, aliquet vel pretium et, molestie et arcu. Mauris lobortis nulla et felis ullamcorper bibendum. Phasellus et hendrerit mauris.

##### Could be a smaller sub-heading, `pacman` (h5)

In arcu magna, aliquet vel pretium et, molestie et arcu. Mauris lobortis nulla et felis ullamcorper bibendum. Phasellus et hendrerit mauris.

###### Small yet significant sub-heading  (h6)

In arcu magna, aliquet vel pretium et, molestie et arcu. Mauris lobortis nulla et felis ullamcorper bibendum. Phasellus et hendrerit mauris.

### Oh hai, an unordered list!!

In arcu magna, aliquet vel pretium et, molestie et arcu. Mauris lobortis nulla et felis ullamcorper bibendum. Phasellus et hendrerit mauris.

- First item, yo
- Second item, dawg
- Third item, what what?!
- Fourth item, fo sheezy my neezy

### Oh hai, an ordered list!!

In arcu magna, aliquet vel pretium et, molestie et arcu. Mauris lobortis nulla et felis ullamcorper bibendum. Phasellus et hendrerit mauris.

1. First item, yo
2. Second item, dawg
3. Third item, what what?!
4. Fourth item, fo sheezy my neezy



## Headings are cool! (h2)

Proin eget nibh a massa vestibulum pretium. Suspendisse eu nisl a ante aliquet bibendum quis a nunc. Praesent varius interdum vehicula. Aenean risus libero, placerat at vestibulum eget, ultricies eu enim. Praesent nulla tortor, malesuada adipiscing adipiscing sollicitudin, adipiscing eget est.

Praesent nulla tortor, malesuada adipiscing adipiscing sollicitudin, adipiscing eget est.

Proin eget nibh a massa vestibulum pretium. Suspendisse eu nisl a ante aliquet bibendum quis a nunc.

### Tables

Title 1               | Title 2               | Title 3               | Title 4
--------------------- | --------------------- | --------------------- | ---------------------
lorem                 | lorem ipsum           | lorem ipsum dolor     | lorem ipsum dolor sit
lorem ipsum dolor sit | lorem ipsum dolor sit | lorem ipsum dolor sit | lorem ipsum dolor sit
lorem ipsum dolor sit | lorem ipsum dolor sit | lorem ipsum dolor sit | lorem ipsum dolor sit
lorem ipsum dolor sit | lorem ipsum dolor sit | lorem ipsum dolor sit | lorem ipsum dolor sit


Title 1 | Title 2 | Title 3 | Title 4
--- | --- | --- | ---
lorem | lorem ipsum | lorem ipsum dolor | lorem ipsum dolor sit
lorem ipsum dolor sit amet | lorem ipsum dolor sit amet consectetur | lorem ipsum dolor sit amet | lorem ipsum dolor sit
lorem ipsum dolor | lorem ipsum | lorem | lorem ipsum
lorem ipsum dolor | lorem ipsum dolor sit | lorem ipsum dolor sit amet | lorem ipsum dolor sit amet consectetur
