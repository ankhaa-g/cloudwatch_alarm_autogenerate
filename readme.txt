Prepare environment for ubuntu

    install aws cli 
        sudo apt-get install python-dev     
        mkdir /tmp/awscli     
        cd /tmp/awscli/     
        curl -O https://bootstrap.pypa.io/get-pip.py      
        python get-pip.py --user      
        export PATH=~/.local/bin:$PATH      
        pip install awscli --upgrade --user     
        which aws     

    configure aws cli
        aws configure
            aws_access_key_id = your keyid
            aws_secret_access_key = your key
            region = ap-northeast-1
        
        above key should have EC2 readonly, Cloudwatch full permissions

    install ruby 2.5

    install aws-sdk gem
        gem install aws-sdk

Run and test on local
    ruby lambda_function.rb

Deploy to AWS    
    Create ruby2.5 lambda function and copy the source codes
    Lambda function must run with EC2ReadOnly, CloudwatchFull permission role 
    Create cloudwatch event wich invokes the function everyday