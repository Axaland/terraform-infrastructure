# Drill Restore RDS Cross-Region

Questo runbook descrive la procedura automatizzata per eseguire un test di Disaster Recovery del database PostgreSQL gestito da AWS RDS partendo da un recovery point creato da AWS Backup e replicato nella regione secondaria.

## Prerequisiti
- AWS CLI v2 configurato con profilo dotato dei permessi `backup:*`, `rds:*`, `ec2:Describe*` e `iam:PassRole` sul ruolo di ripristino.
- PowerShell 5.1+ (raccomandato PowerShell 7 per performance e compatibilità ANSI).
- Ruolo IAM per il drill (`AWSBackupDefaultServiceRole` o analogo personalizzato) con accesso a VPC di destinazione.
- VPC di test nella regione secondaria (`var.backup_replica_region`) con subnet private raggiungibili dal team.

## Procedura ad alto livello
1. Identificazione dell'ultimo recovery point "completed" nella vault di replica (`module.rds_backup.replica_vault_name`).
2. Avvio di un job di restore in regione secondaria creando un'istanza RDS temporanea (`<env>-drill-<timestamp>`).
3. Applicazione di SG e parametri iniziali (multi-AZ disabilitato, copy tags).
4. Verifica connessone applicativa (query di smoke test) e generazione report.
5. Terminazione volontaria della risorsa di drill una volta completato il test.

## Automazione tramite script
Per velocizzare il drill viene fornito lo script PowerShell `infra/scripts/Invoke-RdsDrillRestore.ps1`. Parametri principali:

| Parametro | Descrizione |
|-----------|-------------|
| `-Environment` | Ambiente sorgente (`dev`, `stage`, `prod`). |
| `-Region` | Regione primaria (default `eu-west-1`). |
| `-ReplicaRegion` | Regione replica da cui ripristinare (default `eu-central-1`). |
| `-RestoreSubnetIds` | Lista di subnet private (separate da virgola) in cui lanciare l'istanza di drill. |
| `-SecurityGroupIds` | Security group da associare all'istanza ripristinata. |
| `-DbInstanceClass` | Classe RDS per la prova (default `db.t4g.small`). |
| `-ReplicaBackupVaultName` | (Opzionale) Vault di replica da cui cercare i recovery point. Default: `rds-backup-<env>-replica`. |
| `-DbSubnetGroupName` | (Opzionale) Subnet group da utilizzare se non si forniscono subnet custom. |
| `-AwsProfile` | (Opzionale) Profilo AWS CLI da usare per le chiamate (`--profile`). |
| `-TestQuery` | (Opzionale) Query SQL di smoke test da eseguire sul database ripristinato. |
| `-TestUser` | Utente DB da utilizzare per il test. |
| `-TestDatabase` | Database target su cui eseguire la query. |
| `-TestSecretArn` | ARN del secret Secrets Manager (replica) contenente la password per l'utente di test. |
| `-KeepInstance` | Se specificato, non elimina l'istanza al termine. |

### Esecuzione
```powershell
./infra/scripts/Invoke-RdsDrillRestore.ps1 -Environment prod -ReplicaRegion eu-central-1 -RestoreSubnetIds "subnet-abc,subnet-def" -SecurityGroupIds "sg-0123456789abcdef" -DbInstanceClass db.t4g.small -AwsProfile drill-ops -TestQuery "SELECT count(*) FROM public.users" -TestUser app_read -TestDatabase appdb -TestSecretArn arn:aws:secretsmanager:eu-central-1:123456789012:secret:prod/app-read
```

Lo script produce:
- File JSON con dettagli del recovery point utilizzato (cartella `./drills/<env>/`).
- Report JSON finale con parametro `CleanupScheduled` utile per verificare l'eliminazione.
- Risultato facoltativo dello smoke test (`SmokeTest.status`, `SmokeTest.output` oppure `SmokeTest.error`).
- Log delle operazioni eseguite.
- Identificativo dell'istanza ripristinata (`RdsInstanceId`).

## Operazioni manuali dopo lo script
1. Collegarsi all'istanza di drill usando il secret rotato (`module.rds.db_secret_arn`) nella regione di replica.
2. Eseguire query di verifica (es. conteggio record, sanity check applicativo). Se parametrizzate lo script con `-TestQuery`, questa operazione viene eseguita automaticamente e il risultato è salvato nel report JSON.
3. Approvare il report del drill e caricare l'output in Confluence / repo.

## Pulizia
- Se non si usa `-KeepInstance`, lo script elimina automaticamente l'istanza al termine.
- In caso di interruzione, rimuovere manualmente l'istanza RDS e gli snapshot generati.
- Eliminare i file temporanei in `./drills/<env>/`.

## Frequenza consigliata
- `prod`: trimestrale.
- `stage`: semestrale (facoltativo).
- `dev`: opzionale, solo per verificare eventuali cambi infrastrutturali.

## Metriche di successo
- Tempo totale di recovery (RTO) < 60 minuti.
- Integrità dati verificata (query di smoke test coerenti).
- Cleanup completato senza risorse residue.

## Troubleshooting
- **Backup non trovato**: verificare che la replica cross-region sia completata (`aws backup list-recovery-points-by-resource`).
- **Permessi insufficienti**: controllare il ruolo usato da AWS Backup (`module.rds_backup.backup_plan_id`) e l'eventuale ruolo custom.
- **Connessione fallita**: assicurarsi che la security group configurata permetta l'accesso dall'host di test e che la route table consenta traffico verso la subnet di drill.
```}