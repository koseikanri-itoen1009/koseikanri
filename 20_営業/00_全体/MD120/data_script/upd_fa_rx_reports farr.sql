--KROWN128833�Ή�
--���̑������������݃��|�[�g�ւ̃p�b�`sql
Update fa_rx_reports farr
set concurrent_program_id = 
    (Select concurrent_program_id
     From   fnd_concurrent_programs
     Where  application_id = farr.application_id
     And    concurrent_program_name = farr.concurrent_program_name)
/

