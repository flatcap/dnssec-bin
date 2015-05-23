# dnssec-bin

Generate [DNSSEC](https://en.wikipedia.org/wiki/Domain_Name_System_Security_Extensions) signatures and manage key rollover

## Introduction

I own two domains, `flatcap.org` and `russon.org`.
My registrar for these domains is <https://www.gkg.net/>.
I manage my own DNS (BIND 9) on my VPS at <https://www.linode.com/>.

## Caveats

These are my DNSSEC scripts.  They work for me.
If they work for you, or you can learn something useful, great.
If not, sorry.

I think my scripts work correctly and safely, but I'm not a DNSSEC expert.

## How does DNSSEC work?

DNSSEC relies on two pairs of private/public keys and a SALT.

- Key Signing Key (KSK) - regenerated every three months
- Zone Signing Key (ZSK) - regenerated every month
- [SALT](https://en.wikipedia.org/wiki/Salt_%28cryptography%29) is a random string - regenerated daily

When you've generated the KSK, you upload it's fingerprint to your registrar.
This is used to sign the delegation from the parent zone. e.g.

	KSK fingerprint for flatcap.org is used to sign the flatcap.org link in the .org zone file

The KSK is used to sign the ZSK which is then combined with the SALT to create a signed zone file.
This signed zone is then given to BIND.

## What do the scripts do?

| Script                   | Description                                                                                 |
| ------------------------ | ------------------------------------------------------------------------------------------- |
| cron.sh                  | Called by cron(8) at 05:00 every day                                                        |
| generate-dns-glue        | Local reference to our DNS servers                                                          |
| generate-root-certs      | Local reference to the root DNS servers                                                     |
| generate-ssh-fingerprint | Put SSH fingerprints in DNS records                                                         |
| generate-tlsa            | [DANE](https://en.wikipedia.org/wiki/DNS-based_Authentication_of_Named_Entities) references |
|                          |                                                                                             |
| generate-ksk             | Create a new Key Signing Key                                                                |
| generate-zsk             | Create a new Zone Signing Key                                                               |
| sign-zone                | Sign a domain zone using the KSK                                                            |
| ds-sync.pl               | Send KSK DS Records to domain's registrar                                                   |
|                          |                                                                                             |
| clean                    | Delete all generated files                                                                  |
| delete-old-keys          | Delete keys that expired                                                                    |
| disable-dnssec           | Remove all DNSSEC info from the zones and restart BIND                                      |
| fix-perms                | Set the file permissions on /var/named                                                      |
| log.sh                   | Logging helpers                                                                             |
| set-to-publish-date      | Set the key files' timestamp to match the 'publish' date                                    |
| show-keys                | List all the currently active keys                                                          |
| show-signed              | Quick info about the signed zones                                                           |
| update-serials           | Update the zone's serial number                                                             |

## Links

Some sites where I learnt what I needed to know:

<https://grepular.com/Understanding_DNSSEC>
<https://www.digitalocean.com/community/tutorials/how-to-setup-dnssec-on-an-authoritative-bind-dns-server--2>
<http://www.nlnetlabs.nl/publications/dnssec_howto/>

Testing your domain:

<http://dnssec-debugger.verisignlabs.com/>
<http://dnsviz.net/>
<http://www.dnssy.com/>
<http://dnssec.vs.uni-due.de/>

## License

Copyright &copy; Richard Russon (flatcap).
Distributed under the GPLv3 <http://fsf.org/>

## See also

- [flatcap.org](https://flatcap.org)
- [GitHub](https://github.com/flatcap/dnssec-bin)

