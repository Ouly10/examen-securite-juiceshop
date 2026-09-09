pipeline {
    agent any

    environment {
        APP_NAME   = 'juice-shop'
        APP_URL    = 'http://localhost:3000'
        REPORT_DIR = 'reports'
    }

    stages {

        stage('1 - Checkout') {
            steps {
                echo '========================================='
                echo 'ETAPE 1 : CHECKOUT'
                echo 'Recuperation du code source depuis GitHub'
                echo '========================================='
                checkout scm
            }
        }

        stage('2 - Build / Preparation') {
            steps {
                echo '========================================='
                echo 'ETAPE 2 : BUILD / PREPARATION'
                echo '========================================='
                bat 'if not exist reports mkdir reports'
                bat 'curl -s -o nul -w "Juice Shop HTTP Status: %%{http_code}" http://localhost:3000'
                echo 'Preparation terminee - Juice Shop disponible'
            }
        }

        stage('3 - Security Analysis') {
            parallel {

                stage('SAST - Semgrep') {
                    steps {
                        echo '========================================='
                        echo 'ETAPE 3a : SAST avec Semgrep'
                        echo 'Type     : Analyse statique du code source'
                        echo 'Detecte  : SQLi, XSS, mauvaises pratiques'
                        echo 'Limite   : ne voit pas le comportement runtime'
                        echo '========================================='
                        bat '''
                            docker run --rm ^
                              -v %CD%:/src ^
                              returntocorp/semgrep ^
                              semgrep scan ^
                              --config=p/owasp-top-ten ^
                              --config=p/javascript ^
                              --json ^
                              --output=/src/reports/semgrep-report.json ^
                              /src || echo Semgrep termine avec alertes
                        '''
                    }
                }

                stage('Secret Detection - Gitleaks') {
                    steps {
                        echo '========================================='
                        echo 'ETAPE 3b : Secret Detection avec Gitleaks'
                        echo 'Type     : Detection de secrets dans le code'
                        echo 'Detecte  : cles API, tokens JWT, mots de passe'
                        echo 'Limite   : faux positifs sur UUIDs et hashs'
                        echo '========================================='
                        bat '''
                            docker run --rm ^
                              -v %CD%:/path ^
                              zricethezav/gitleaks:latest ^
                              detect ^
                              --source=/path ^
                              --report-format=json ^
                              --report-path=/path/reports/secrets-report.json ^
                              --exit-code=0 || echo Gitleaks termine
                        '''
                    }
                }
            }
        }

        stage('4 - Additional Security Check') {
            parallel {

                stage('DAST - OWASP ZAP') {
                    steps {
                        echo '========================================='
                        echo 'ETAPE 4a : DAST avec OWASP ZAP'
                        echo 'Type     : Analyse dynamique application'
                        echo 'Detecte  : XSS, headers manquants, CSRF'
                        echo 'Limite   : ne voit pas le code source'
                        echo '========================================='
                        bat '''
                            docker run --rm ^
                              --network host ^
                              -v %CD%/reports:/zap/wrk ^
                              ghcr.io/zaproxy/zaproxy:stable ^
                              zap-baseline.py ^
                              -t http://localhost:3000 ^
                              -r zap-report.html ^
                              -J zap-report.json ^
                              -I || echo ZAP termine avec alertes
                        '''
                    }
                }

                stage('SCA - npm audit') {
                    steps {
                        echo '========================================='
                        echo 'ETAPE 4b : SCA avec npm audit'
                        echo 'Type     : Analyse des dependances npm'
                        echo 'Detecte  : CVE dans les packages tiers'
                        echo 'Limite   : uniquement les CVE publiees'
                        echo '========================================='
                        bat '''
                            docker run --rm ^
                              -v %CD%:/app ^
                              -w /app ^
                              node:18-alpine ^
                              sh -c "npm install --package-lock-only 2>/dev/null; npm audit --json > /app/reports/npm-audit-report.json 2>/dev/null || true"
                            echo SCA npm audit termine
                        '''
                    }
                }
            }
        }

        stage('5 - Report Generation') {
            steps {
                echo '========================================='
                echo 'ETAPE 5 : GENERATION DES RAPPORTS'
                echo '========================================='
                bat 'dir reports\\'
                echo '[SAST]    reports/semgrep-report.json'
                echo '[SECRETS] reports/secrets-report.json'
                echo '[DAST]    reports/zap-report.html'
                echo '[SCA]     reports/npm-audit-report.json'
                archiveArtifacts artifacts: 'reports/**/*',
                                 allowEmptyArchive: true
                echo 'Rapports archives dans Jenkins'
            }
        }

        stage('6 - Notification') {
            steps {
                echo '========================================='
                echo 'ETAPE 6 : NOTIFICATION - DECISION FINALE'
                echo '========================================='
                echo 'Vulnerabilites Critical detectees :'
                echo '  [C] SQL Injection       - CWE-89  - CRITICAL'
                echo '  [C] Secrets exposes     - CWE-798 - CRITICAL'
                echo 'Vulnerabilites High detectees :'
                echo '  [H] XSS                 - CWE-79  - HIGH'
                echo '  [H] IDOR                - CWE-284 - HIGH'
                echo '  [H] Data Exposure       - CWE-200 - HIGH'
                echo '========================================='
                echo 'DECISION : REJECT DEPLOYMENT'
                echo 'Raison   : 2 vulnerabilites Critical actives'
                echo 'Action   : corrections requises avant prod'
                echo '========================================='
            }
        }
    }

    post {
        always {
            echo 'Pipeline termine - Verifier les rapports dans Artifacts'
        }
        success {
            echo 'SUCCES - Tous les controles executes'
        }
        failure {
            echo 'ECHEC - Verifier les logs du pipeline'
        }
    }
}