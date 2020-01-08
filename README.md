# Enterprise Application Solution for Yield
This repo was set up for Maryville University's *Enterprise Application Solution for Yield*.

## Synopsis
*Enterprise Application Solution for Yield* (EASY) is a “builder,” which is designed to be a user tool so departments can control their own application. It’s an extension of Salesforce’s approach to “democratizing” software. That is, the same way that Salesforce democratized software by separating declarative functionality from coding, EASY democratizes declarative and user functionality, separating application and question/requirement setup from administrative setup of fields and picklist values. The latter most often are associated with IPEDS and/or SIS fields in global picklist sets, minimizing the initial and support work required by system administrators.

That means users control most of the functions of the solution rather than having to heavily rely on the IT department for updates to existing questions or new applications. The user tool approach, then, equates to empowerment for departments.

The solution includes an unmanaged package (the EASY Package), resource documents, and code via this GIT repository.

We welcome contributions and feedback. Read below for more information about how to get involved!

## Installation
You can install EASY as-is into any Developer Edition, Sandbox, Enterprise, or higher edition org using these unmanaged package links and the <a href="https://github.com/SalesforceFoundation/EASY-Open-Source-Solution/blob/master/Docs/Installation%20Guide%20-%20EASY.pdf" target="_blank">Installation Guide</a>:

* <a href="https://test.salesforce.com/packaging/installPackage.apexp?p0=04t2E000003ZR5Y" target="_blank">Install EASY in a Sandbox</a>
* <a href="https://login.salesforce.com/packaging/installPackage.apexp?p0=04t2E000003ZR5Y" target="_blank">Install EASY in a Production or Developer Org</a>

Alternatively, you can fork this repository and deploy the unmanaged version of the code into a Salesforce org of your choice.

* Fork the repository by clicking on the "Fork" button in the upper-righthand corner. This creates your own copy of EASY for your Github user.
* Clone your fork to your local machine via the command line
```sh
$ git clone https://github.com/SalesforceFoundation/EASY-Open-Source-Solution.git
```
* You now have a local copy on your machine. EASY has some built-in scripts to make deploying to your Salesforce org easier. Utilizing ant and the Force.com Migration tool, you can push your local copy of EASY to the org of your choice. You'll need to provide a build.properties to tell ant where to deploy. An example file might look like:

```
sf.username = YOUR_ORG_USERNAME
sf.password = YOUR_ORG_PASSWORD
sf.serverurl = https://login.salesforce.com ##or test.salesforce.com for sandbox environments
sf.maxPoll = 20
```

* Now deploy to your org utilizing ant

```sh
$ cd EASY-Open-Source-Solution
$ ant deploy
```

## Maintenance and Collaboration
Thank you for your interest in EASY. This project's code is provided as-is, and is not actively maintained. The developers invite you to peruse their code and even use it in your next project, provided you follow the included license. There is no guarantee of support for the code (including submitted Issues). There is no guarantee that pull requests will be reviewed or merged. It's open-source, so forking is permitted; just be sure to give credit where it's due.

If you are interested in learning about the project roles, roadmap, how to become a collaborator, and/or where to find the community surrounding this project, then please review our <a href="https://github.com/SalesforceFoundation/EASY-Open-Source-Solution/blob/master/Maintenance-Policy.md" target="_blank">Maintenance Policy</a>.

## Documentation and Other Resources
EASY comes with a wealth of documentation and other resources to help admins, developers, and users implement, use, and customize the solution. It is important to read through these materials before downloading the EASY package, as they contain important information necessary for a successful implementation.

### Documentation Guides
* <a href="https://github.com/SalesforceFoundation/EASY-Open-Source-Solution/blob/master/Docs/User%20Guide%20-%20EASY.pdf" target="_blank">User Guide</a> – This guide is both for admins and end users (e.g. application administrators) to learn about best practices for using EASY and all its features.
* <a href="https://github.com/SalesforceFoundation/EASY-Open-Source-Solution/blob/master/Docs/Installation%20Guide%20-%20EASY.pdf" target="_blank">Installation Guide</a> – The Installation Guide is an important resource for administrators looking to implement EASY with step-by-step instructions for installation and post-installation requirements and recommendations.
* <a href="https://github.com/SalesforceFoundation/EASY-Open-Source-Solution/blob/master/Docs/Technical%20Guide%20-%20EASY.pdf" target="_blank">Technical Guide</a> – This guide is geared toward developers and admins experienced with Apex to learn more about how the EASY classes function and some customization tips.

## Interactions for Student Recruitment

EASY includes a modified version of University of Miami’s <a href="https://github.com/SalesforceFoundation/Interactions-for-Student-Recruitment" target="_blank">Interactions for Student Recruitment package</a>. Specifically, any references to HEDA objects in the codebase have been abstracted to first test for the existence of those objects before executing the code. Also, the Plan__c object has been renamed to Program__c in EASY. If you’re installing EASY after first installing/implementing Interactions for Student Recruitment, this may mean you need to migrate all Plan__c records over to the Program__c object.

Much more information, including the Documentation Guides that explain the use and benefit of Interactions for Student Recruitment, can be found on the Salesforce Foundation GIT Respository <a href="https://github.com/SalesforceFoundation/Interactions-for-Student-Recruitment" target="_blank">here</a>.

## License

These terms and conditions are provided specifically for your participation in the *Enterprise Application Solution for Yield* project and exist independently of any Master Subscription Agreement (MSA) terms you or your organization may have or may in the future agree with either Salesforce.org or Salesforce.com.

The *Enterprise Application Solution for Yield* project code repository is provided on “as-is” and “as-available” bases for exclusive use by *Enterprise Application Solution for Yield* grantees and their co-contributors, Salesforce.org and Salesforce.com contributors, and others associated with the *Enterprise Application Solution for Yield* initiative. Although maintained within the Salesforce.org repository at GitHub, Salesforce.org makes no express, implied, or other warranty of any kind regarding the *Enterprise Application Solution for Yield* repository. To the fullest extent permitted by applicable laws, Salesforce.org disclaims, without limitation, warranties of merchantability, fitness for a particular purpose, freedom from defects, and non-infringement. Salesforce.org has no liability to you or any other party arising from your use of this project repository, including without limitation any liability for direct, indirect, consequential, punitive, special, exemplary, or cover damages, regardless the nature of a claim or theory of liability. The foregoing disclaimer applies even if you advise Salesforce.org of the possibility of such damages.

The nature of this project is such that active maintenance of this repository is not guaranteed by Salesforce.org or any other party or entity. Salesforce.org has relinquished control of the information comprising this code repository and has no obligation to protect the integrity, confidentiality, or availability of said information. Any reference to specific commercial products, or services, other than those services provided by Salesforce.org or Salesforce.com, by reference to trademarks or service marks does not imply any endorsement or recommendation by either Salesforce.org or Salesforce.com. No license to use trademarks or service marks belonging to either Salesforce.org or Salesforce.com is conveyed to you in these terms and conditions.

Some jurisdictions may not allow the exclusion of certain warranties or the limitation of liability for certain types of damages, and thus some of the above exclusions and limitations may not apply to particular users of this repository. If these disclaimers, exclusions, and limitations cannot be given local legal effect according to the terms and conditions described herein, you agree that reviewing courts will apply local laws which most closely approximate an absolute waiver of all civil liability in connection with the *Enterprise Application Solution for Yield* project and code repository.

## Acknowledgements

Thanks to the following individuals in the Github community who helped shape the README.md:

* <a href="https://gist.github.com/jxson" target="_blank">@jxson</a> for the <a href="https://gist.github.com/jxson/1784669" target="_blank"> readme </a> example
* <a href="https://github.com/potch" target="_blank">@potch</a> for the <a href="https://github.com/potch/unmaintained.tech"> No Maintenance Intended </a> example
* <a href="https://guides.github.com/" target="_blank">Github Guides</a>
    * <a href="https://guides.github.com/introduction/getting-your-project-on-github/" target="_blank">Getting your project on Github</a>
    * <a href="https://guides.github.com/features/wikis/#creating-a-readme" target="_blank">Documenting your projects on Github</a>
    * <a href="https://guides.github.com/features/mastering-markdown/" target="_blank">Mastering Markdown</a>
    * <a href="https://guides.github.com/introduction/flow/" target="_blank">Understanding the GitHub Flow</a>
* <a href="https://help.github.com/articles/github-glossary/" target="_blank">Github Glossary</a>
