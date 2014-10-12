ruby-auto-tos-locator
=====================

A small thing which locates the text of Terms of Services on a given webpage.

Motivation
----------

ToSBack is a great project which keeps track of changes that might happen
silently in Terms of Service or even Privacy Policies of Web services. Adding a
new rule to the system, however, is [quite
complex](https://www.eff.org/deeplinks/2013/01/campus-party-hackathon-making-rule-contribution-tosback),
especially for a non-technical user. The aim of this project is to simplify the
process as much as possible. Its ultimate goal is to make adding a new rule as
simple as pasting a URL of a service to a web form.

Installation
------------

All you need should get installed fairly quickly by running

    $ bundle install

Note that you need [bundler](http://bundler.io/) for that -- you can install
that by running (`gem install bundler`).

Usage
-----

To find the XPath for the privacy policy located at
`https://www.khanacademy.org/about/privacy-policy` one can run

    $ ./locator.rb https://www.khanacademy.org/about/privacy-policy

The output should consist of the extracted Privacy Policy and XML that
specifies the rule. An example can be find below

```
[Privacy Policy removed due to its extensive length ...]

<sitename name="khanacademy.org">
  <docname name="Privacy Policy">
    <url name="https://www.khanacademy.org/about/privacy-policy" xpath="//article[@id='privacy-policy']">
     <norecurse name="arbitrary"/>
    </url>
  </docname>
</sitename>

```
