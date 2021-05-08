# Generating TypeScript types.d.ts files from JSDoc


## Relevant JSDoc Tags

* `@module` is for filename.
* `@class`/`@function`/`@const` is for marking a variable as a type if it's in a context that isn't made obvious by the interpreter (e.g. `const myFunc = () => {};`).
* `@interface`/`@type` is for type definitions.
    - `@interface` is better for objects because they are automatically merged if declared more than once.
* `@namespace` is for nested properties (functions, classes, vars) and for internal types.
    - It's also useful for allowing `import * as Stuff from 'my-file';` because in `* as Stuff`, "Stuff" is the "namespace" that all exported things were nested inside.
    - Allows you to export your internal types (e.g. for `myFunc(specialObjStructure)`).
* `import` and `<reference>` allow you to import types from other files.
    - `@typedef {import('./MyClass').MyMethodParams} MyMethodParams`
        + Defines a new type of the same name as the imported file's type.
        + More time-consuming if importing many types.
        + Safe with TypeScript (and other types.d.ts generation systems) as it has a direct reference to what you're wanting to define.
    - `<reference path="./MyClass.js" />`
        + Imports all types from from the file.
        + Saves time when importing many types by not having to declare them individually.
        + Not safe with TypeScript/types.d.ts systems as it doesn't have direct references to what you're wanting to define.


## Examples

### Exporting something as the default.

Usage: `import MyClass from 'my-class.js';`

See:

* [Classes](https://www.typescriptlang.org/docs/handbook/declaration-files/templates/module-class-d-ts.html)
* [Functions](https://www.typescriptlang.org/docs/handbook/declaration-files/templates/module-function-d-ts.html)
* [Modules](https://www.typescriptlang.org/docs/handbook/declaration-files/templates/module-d-ts.html)

1. In types.d.ts
    ```javascript
    // same for functions/variables: declare function func(); export = func;
    declare class MyClass {
        someVar: number;
        myMethod(arg1: string, opts: MyClass.MyMethodOptions): void;
    }

    /**
     * Like what was said about `@interface` above, the MyClass class declaration
     * and namespace declaration are both merged into one since they have the same
     * name. This is why we only have to export MyClass once and it will automatically
     * include the namespace fields with it.
     *
     * Alternatively, you could simply export the interfaces directly without
     * the namespace to avoid having to prefix MyMethodOptions with MyClass;
     */
    declare namespace MyClass {
        export interface MyMethodOptions {
            opt1?: string;
            opt2?: number;
        }
    }
    export = MyClass; // note the equivalence between this and `export default X`
    ```

2. In my-class.ts
    ```javascript
    export default class MyClass {...};
    ```


### Exporting non-default/named fields.

Usage: `import { x, MyClass } from 'my-file.js';`

1. In types.d.ts
    ```javascript
    declare class MyClass {
        myMethod(arg1: string, opts: MyNamespace.MyMethodOptions): void;
    }

    /**
     * Unlike the first example, we don't want to default-export MyClass,
     * but instead require it to be a named export.
     * Thus, we nest MyClass inside the MyNamespace and export that instead.
     */
    declare namespace MyNamespace {
        // Note that we have to export entries within the namespace
        // to make them accessible to users.
        export interface MyMethodOptions {
            opt1?: string;
            opt2?: number;
        }
        export const x: number; // import { x } from 'my-file'
        export const MyClass: MyClass; // import { MyClass } from 'my-file'
    }
    export = MyNamespace;
    /**
     * Note how we have to nest everything (including MyClass itself) in the namespace.
     * This forces users to import the named fields via named imports.
     *
     * `import * as UserDefinedName from 'my-file.js'` is not allowed
     * unless --esModuleInterop is turned on.
     */
    ```

2. In my-file.ts
    ```javascript
    export interface MyMethodOptions {
        opt1?: string;
        opt2?: number;
    }
    export class MyClass {
        myMethod(arg1: string, opts: MyMethodOptions) {...implementation};
    }
    export const x: number;
    export const MyClass: MyClass;
    ```
