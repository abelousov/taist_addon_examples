Addon allows to create list of components and assign issues to them to:

* filter issues by components
* automatically set Assignee by setting a component - each component has a person responsible for it

### Features:

* assign components during issue creation or editing
* if component is set during issue creation assignee will be set automatically
* When you set component on existing issue it is saved automatically; assignee is not changed
* components can be required or optional

### Setting up:

* Go to new tab "Components" on the repository page
* Check **"Enabled"** - components are enabled on repository-level

  * addon will work for each repository collaborator that has activated it - no additional access setting is needed  

* Check **"Required in task"** if you want to always require assigning a component to an issue
* Set components list - each component consists of *Id*, *name* and *account of the responsible person*. Example:

```javascript
1,Authorization,abelousov
2,User manual,lalaki
```

* Hit *Save* and enjoy!

### How it works
* Addon uses `taistApi.companyData` to store kist of components and their links to issues.
* Additional UI is mainly created manually
