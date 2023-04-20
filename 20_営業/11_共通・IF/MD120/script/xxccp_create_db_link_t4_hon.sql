/*************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 *
 * DATABASE LINK Name : T4_HON
 * Description        : T4���{�Ԋ��̃f�[�^�x�[�X�����N
 * Version            : 1.1
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2015/10/29    1.0   S.Niki       �V�K�쐬
 *  2022/11/01    1.1   H.Iitsuka    Iaas Rift ��̊��ɏC��
 ************************************************************************/
CREATE DATABASE LINK t4_hon CONNECT TO APPS IDENTIFIED BY APPS
USING '(DESCRIPTION=
         (ADDRESS_LIST=
           (ADDRESS=(PROTOCOL=tcp)(HOST=bebsdb31.itoen.master)(PORT=1521))
           (ADDRESS=(PROTOCOL=tcp)(HOST=bebsdb21.itoen.master)(PORT=1521))
           (ADDRESS=(PROTOCOL=tcp)(HOST=bebsdb11.itoen.master)(PORT=1521))
         )
         (CONNECT_DATA=
           (SERVICE_NAME=BEBSITO.itoen.master))
      )'
;
