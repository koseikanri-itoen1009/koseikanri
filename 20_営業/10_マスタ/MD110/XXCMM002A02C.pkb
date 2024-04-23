CREATE OR REPLACE PACKAGE BODY XXCMM002A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM002A02C(body)
 * Description      : �Ј��f�[�^�A�g(���̋@)
 * MD.050           : �Ј��f�[�^�A�g(���̋@) MD050_CMM_002_A02
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ���������v���V�[�W��(A-1)
 *  get_people_data        �Ј��f�[�^�擾�v���V�[�W��(A-2)
 *  output_csv             CSV�t�@�C���o�̓v���V�[�W��(A-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/29    1.0   SCS ���� �M�q    ����쐬
 *  2009/09/09    1.1   SCS �v�ۓ� �L    ��Q0000337 �]�ƈ��̒��o������ύX
 *                                       ( 4(�_�~�[)�ȊO -> 1(�Ј�)�܂���3(�h���Ј�) )
 *  2016/02/24    1.2   SCSK ���H ���O   E_�{�ғ�_13456�Ή�
 *  2016/03/24    1.3   SCSK ���c �p�P   E_�{�ғ�_13456�ǉ��Ή�
 *  2024/04/16    1.4   SCSK ���R �O     E_�{�ғ�_19873�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  lock_expt                 EXCEPTION;        -- ���b�N(�r�W�[)�G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCMM002A02C';               -- �p�b�P�[�W��
  -- �v���t�@�C��
  cv_filepath               CONSTANT VARCHAR2(30)  := 'XXCMM1_JIHANKI_OUT_DIR';     -- ���̋@CSV�t�@�C���o�͐�
  cv_filename               CONSTANT VARCHAR2(30)  := 'XXCMM1_002A02_OUT_FILE';     -- �A�g�pCSV�t�@�C����
-- 2009/09/09 Ver1.1 delete start by Y.Kuboshima
--  cv_jyugyoin_kbn           CONSTANT VARCHAR2(30)  := 'XXCMM1_002A02_JYUGYOIN_KBN'; -- �]�ƈ��敪�̃_�~�[�l
-- 2009/09/09 Ver1.1 delete end by Y.Kuboshima
  -- �g�[�N��
  cv_tkn_profile            CONSTANT VARCHAR2(10)  := 'NG_PROFILE';                 -- �v���t�@�C����
  cv_tkn_filepath_nm        CONSTANT VARCHAR2(20)  := 'CSV�t�@�C���o�͐�';
  cv_tkn_filename_nm        CONSTANT VARCHAR2(20)  := 'CSV�t�@�C����';
-- 2009/09/09 Ver1.1 delete start by Y.Kuboshima
--  cv_tkn_jyugoin_kbn_nm     CONSTANT VARCHAR2(20)  := '�]�ƈ��敪�̃_�~�[�l';
-- 2009/09/09 Ver1.1 delete end by Y.Kuboshima
  cv_tkn_word               CONSTANT VARCHAR2(10)  := 'NG_WORD';                    -- ���ږ�
  cv_tkn_word1              CONSTANT VARCHAR2(10)  := '�Ј��ԍ�';
  cv_tkn_word2              CONSTANT VARCHAR2(10)  := '�A���� : ';
  cv_tkn_data               CONSTANT VARCHAR2(10)  := 'NG_DATA';                    -- �f�[�^
  cv_tkn_filename           CONSTANT VARCHAR2(10)  := 'FILE_NAME';                  -- �t�@�C����
  cv_tkn_table              CONSTANT VARCHAR2(10)  := 'NG_TABLE';                   -- �e�[�u��
  cv_tkn_table_nm1          CONSTANT VARCHAR2(20)  := '�A�T�C�������g�}�X�^';
-- 2009/09/09 Ver1.1 modify start by Y.Kuboshima
--  cv_tkn_table_nm2          CONSTANT VARCHAR2(40)  := '���̋@�����A�g�p�Ј��f�[�^�e�[�u��';
-- 2016/02/24 Ver1.2 Del Start
--  cv_tkn_table_nm2          CONSTANT VARCHAR2(40)  := '�A���̋@�����A�g�p�Ј��f�[�^�e�[�u��';
-- 2016/02/24 Ver1.2 Del End
-- 2009/09/09 Ver1.1 modify end by Y.Kuboshima
  cv_tkn_value              CONSTANT VARCHAR2(10)  := 'VALUE';                      -- ���ږ�
  cv_tkn_value_nm1          CONSTANT VARCHAR2(10)  := '�Ј��ԍ�';
-- 2016/02/24 Ver1.2 Del Start
--  cv_tkn_value_nm2          CONSTANT VARCHAR2(10)  := '���ߓ�';
-- 2016/02/24 Ver1.2 Del End
  cv_tkn_value_nm3          CONSTANT VARCHAR2(10)  := '����(��)';
-- 2016/02/24 Ver1.2 Del Start
--  cv_tkn_value_nm4          CONSTANT VARCHAR2(10)  := '�J�i(��)';
-- 2016/02/24 Ver1.2 Del End
  cv_tkn_value_nm5          CONSTANT VARCHAR2(10)  := '�N�[����';
  cv_tkn_value_nm6          CONSTANT VARCHAR2(10)  := '����(��)';
-- 2016/02/24 Ver1.2 Del Start
--  cv_tkn_value_nm7          CONSTANT VARCHAR2(10)  := '�J�i(��)';
-- 2016/02/24 Ver1.2 Del End
  cv_tkn_param              CONSTANT VARCHAR2(10)  := 'PARAM';                      -- �p�����[�^��
  cv_tkn_param1             CONSTANT VARCHAR2(10)  := '�J�n��';
  cv_tkn_param2             CONSTANT VARCHAR2(10)  := '�I����';
  cv_tkn_param3             CONSTANT VARCHAR2(20)  := '���̓p�����[�^';
  cv_tkn_ng_value           CONSTANT VARCHAR2(10)  := 'NG_VALUE';                   -- ���ږ�
---- 2016/02/24 Ver1.2 Add Start
  cv_tkn_department_code    CONSTANT VARCHAR2(15)  := 'DEPARTMENT_CODE';            -- ���_
  cv_tkn_employee_number    CONSTANT VARCHAR2(15)  := 'EMPLOYEE_NUMBER';            -- �]�ƈ�
---- 2016/03/16 Ver1.2 Add End
  -- ���b�Z�[�W�敪
  cv_msg_kbn_cmm            CONSTANT VARCHAR2(5)   := 'XXCMM';
  cv_msg_kbn_ccp            CONSTANT VARCHAR2(5)   := 'XXCCP';
  -- ���b�Z�[�W
  cv_msg_00218              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00218';           -- ���̓p�����[�^�w��G���[(�I�����̂ݎw��)
  cv_msg_00038              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00038';           -- ���̓p�����[�^�o�̓��b�Z�[�W
  cv_msg_00002              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';           -- �v���t�@�C���擾�G���[
  cv_msg_05102              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-05102';           -- �t�@�C�����o�̓��b�Z�[�W
  cv_msg_00018              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00018';           -- �Ɩ����t�擾�G���[
  cv_msg_00030              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00030';           -- �Ώۊ��Ԑ����G���[
  cv_msg_00019              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00019';           -- �Ώۊ��Ԏw��G���[
  cv_msg_00010              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00010';           -- CSV�t�@�C�����݃`�F�b�N
  cv_msg_00003              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00003';           -- �t�@�C���p�X�s���G���[
  cv_msg_00008              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00008';           -- ���b�N�擾NG���b�Z�[�W
  cv_msg_00209              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00209';           -- �]�ƈ��ԍ��d�����b�Z�[�W
  cv_msg_00216              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00216';           -- �֑��������݃`�F�b�N���b�Z�[�W
-- 2016/02/24 Ver1.2 Del Start
--  cv_msg_00217              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00217';           -- �ߋ��A�g�f�[�^�擾�G���[
-- 2016/02/24 Ver1.2 Del End
  cv_msg_00007              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00007';           -- �t�@�C���A�N�Z�X�����G���[
  cv_msg_00009              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00009';           -- CSV�f�[�^�o�̓G���[
-- 2016/02/24 Ver1.2 Del Start
--  cv_msg_00032              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00032';           -- ���̋@�����A�g�p�Ј��f�[�^�e�[�u���X�V�G���[
-- 2016/02/24 Ver1.2 Del End
  cv_msg_00029              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00029';           -- �A�T�C�������g�}�X�^�X�V�G���[
-- 2016/02/24 Ver1.2 Add Start
  cv_msg_00224              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00224';           -- ���F�ҕ����x��
-- 2016/02/24 Ver1.2 Add End
  -- �Œ�l(�ݒ�l)
-- 2016/02/24 Ver1.2 Del Start
--  cv_riyou_kbn              CONSTANT VARCHAR2(2)   := '02';                         -- ���p�ҋ敪
--  cv_99999999               CONSTANT VARCHAR2(8)   := '99999999';                   -- �K�p�I����(���ߓ�=���ДN����)
-- 2016/02/24 Ver1.2 Del End
  cv_team_cd                CONSTANT VARCHAR2(4)   := '0000';                       -- �`�[���R�[�h
-- 2016/02/24 Ver1.2 Del Start
--  cv_flg_0                  CONSTANT NUMBER(1)     := 0;                            -- ���p��~�t���O(0)
--  cv_flg_1                  CONSTANT NUMBER(1)     := 1;                            -- ���p��~�t���O(1)
--  cv_tanto_cd               CONSTANT VARCHAR2(5)   := '99999';                      -- �X�V�S���҃R�[�h
--  cv_busyo_cd               CONSTANT VARCHAR2(6)   := '999999';                     -- �X�V�����R�[�h
--  cv_program_id             CONSTANT VARCHAR2(10)  := 'USER_ULD';                   -- �X�V�v���O����ID
-- 2016/02/24 Ver1.2 Del End
  cv_chk_cd                 CONSTANT VARCHAR2(22)  := 'VENDING_MACHINE_SYSTEM';     -- ���̋@�V�X�e���`�F�b�N
  cv_flg_t                  CONSTANT VARCHAR2(1)   := 'T';                          -- ���s�t���O(T:���)
  cv_flg_r                  CONSTANT VARCHAR2(1)   := 'R';                          -- ���s�t���O(R:����(���J�o��))
-- 2009/09/09 Ver1.1 add start by Y.Kuboshima
  cv_jyugyoin_kbn_1         CONSTANT VARCHAR2(1)   := '1';                          -- �]�ƈ��敪(1:�Ј�)
  cv_jyugyoin_kbn_3         CONSTANT VARCHAR2(1)   := '3';                          -- �]�ƈ��敪(3:�h���Ј�)
-- 2009/09/09 Ver1.1 add end by Y.Kuboshima
-- 2016/02/24 Ver1.2 Add Start
  cv_customer_class_code_1  CONSTANT VARCHAR2(1)   := '1';                          -- ���_
  cv_del_flg_0              CONSTANT VARCHAR2(1)   := '0';                          -- �폜�t���O(0)
  cv_del_flg_1              CONSTANT VARCHAR2(1)   := '1';                          -- �폜�t���O(1)
  cv_department_flg_1       CONSTANT VARCHAR2(1)   := '1';                          -- (HOST)�P�ہE�Q�ۃt���O:1
  cv_date_format_yyyymmdd   CONSTANT VARCHAR2(8)   := 'YYYYMMDD';                   -- ���t�����FYYYYMMDD
  cv_y                      CONSTANT VARCHAR2(1)   := 'Y';                          -- �t���O�FY
  cv_n                      CONSTANT VARCHAR2(1)   := 'N';                          -- �t���O�FN
  -- ����
  ct_user_lang              CONSTANT  fnd_lookup_values.language%TYPE := USERENV( 'LANG' );
  -- �Q�ƃ^�C�v
  cv_approve_code           CONSTANT VARCHAR2(19)  := 'XXCMM_APPROVE_CODE';         -- ���F�҃R�[�h
-- 2016/02/24 Ver1.2 Add End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �Ј��f�[�^���i�[���郌�R�[�h
  TYPE data_rec  IS RECORD(
-- 2016/02/24 Ver1.2 Del Start
--       person_id                per_all_people_f.person_id%TYPE,                      -- �]�ƈ�ID
-- 2016/02/24 Ver1.2 Del End
       employee_number          per_all_people_f.employee_number%TYPE,                -- �]�ƈ��ԍ�
       effective_start_date     per_all_people_f.effective_start_date%TYPE,           -- ���ДN����
       actual_termination_date  per_periods_of_service.actual_termination_date%TYPE,  -- �ސE�N����
       per_information18        per_all_people_f.per_information18%TYPE,              -- ������
       per_information19        per_all_people_f.per_information19%TYPE,              -- ������
-- 2016/02/24 Ver1.2 Del Start
--       last_name                per_all_people_f.last_name%TYPE,                      -- �J�i��
--       first_name               per_all_people_f.first_name%TYPE,                     -- �J�i��
-- 2016/02/24 Ver1.2 Del End
       attribute28              per_all_people_f.attribute28%TYPE,                    -- �N�[����
       ass_attribute2           per_all_assignments_f.ass_attribute2%TYPE,            -- ���ߓ�
       ass_attribute17          per_all_assignments_f.ass_attribute17%TYPE,           -- �����A�g�p���t(���̋@)
       assignment_id            per_all_assignments_f.assignment_id%TYPE,             -- �A�T�C�������gID
       j_update_date            per_all_people_f.last_update_date%TYPE,               -- �]�ƈ�.�ŏI�X�V��
-- 2016/02/24 Ver1.2 Mod Start
--       a_update_date            per_all_assignments_f.last_update_date%TYPE           -- �A�T�C�������g.�ŏI�X�V��
       a_update_date            per_all_assignments_f.last_update_date%TYPE,           -- �A�T�C�������g.�ŏI�X�V��
       attribute11              per_all_people_f.attribute11%TYPE,                    -- �E�ʃR�[�h�i�V�j
       attribute13              per_all_people_f.attribute13%TYPE,                    -- �E�ʃR�[�h�i���j
       area_code                hz_locations.address3%TYPE                            -- �n��R�[�h
-- 2016/02/24 Ver1.2 Mod End
  );
  -- �Ј��f�[�^���i�[����e�[�u���^�̒�`
  TYPE data_tbl  IS TABLE OF data_rec INDEX BY BINARY_INTEGER;
-- 2016/03/24 Ver1.3 Add Start
  -- ���_�ʂ̏��F�҂��i�[����e�[�u���^�̒�`
  TYPE g_base_applover_ttype IS TABLE OF per_people_f.employee_number%TYPE INDEX BY VARCHAR2(4);
-- 2016/03/24 Ver1.3 Add End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_filepath               VARCHAR2(255);        -- �A�g�pCSV�t�@�C���o�͐�
  gv_filename               VARCHAR2(255);        -- �A�g�pCSV�t�@�C����
-- 2009/09/09 Ver1.1 delete start by Y.Kuboshima
--  gv_jyugyoin_kbn           VARCHAR2(10);         -- �]�ƈ��敪�̃_�~�[�l
-- 2009/09/09 Ver1.1 delete end by Y.Kuboshima
  gd_process_date           DATE;                 -- �Ɩ����t
  gd_select_start_date      DATE;                 -- �擾�J�n��
  gd_select_start_datetime  DATE;                 -- �擾�J�n��(���� 00:00:00)
  gd_select_end_date        DATE;                 -- �擾�I����
  gd_select_end_datetime    DATE;                 -- �擾�I����(���� 23:59:59)
  gf_file_hand              UTL_FILE.FILE_TYPE;   -- �t�@�C���E�n���h���̐錾
  gv_warn_flg               VARCHAR2(1);          -- �x���t���O
  gv_run_flg                VARCHAR2(1);          -- ���s�t���O(T:����AR:����(���J�o��))
  gv_date_from              VARCHAR2(10);         -- ���̓p�����[�^�F�J�n��
  gv_date_to                VARCHAR2(10);         -- ���̓p�����[�^�F�I����
  gt_data_tbl               data_tbl;             -- �����z��̒�`
  gv_param_output_flg       VARCHAR2(1);          -- ���̓p�����[�^�o�̓t���O(�o�͑O:0�A�o�͌�:1)
-- 2016/03/24 Ver1.3 Add Start
  gt_base_applover_tab      g_base_applover_ttype; -- ���_�ʏ��F��
-- 2016/03/24 Ver1.3 Add End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  -- �Ј��f�[�^(������s��)
  CURSOR get_t_data_cur
  IS
-- 2016/02/24 Ver1.2 Mod Start
--    SELECT   p.person_id AS person_id,                              -- �]�ƈ�ID
--             p.employee_number AS employee_number,                  -- �]�ƈ��ԍ�
    SELECT   p.employee_number AS employee_number,                  -- �]�ƈ��ԍ�
-- 2016/02/24 Ver1.2 Mod End
             p.effective_start_date AS effective_start_date,        -- ���ДN����
             t.actual_termination_date AS actual_termination_date,  -- �ސE�N����
             p.per_information18 AS per_information18,              -- ������
             p.per_information19 AS per_information19,              -- ������
-- 2016/02/24 Ver1.2 Del Start
--             p.last_name AS last_name,                              -- �J�i��
--             p.first_name AS first_name,                            -- �J�i��
-- 2016/02/24 Ver1.2 Del End
             p.attribute28 AS attribute28,                          -- �N�[����
             a.ass_attribute2 AS ass_attribute2,                    -- ���ߓ�
             a.ass_attribute17 AS ass_attribute17,                  -- �����A�g�p���t(���̋@)
             a.assignment_id AS assignment_id,                      -- �A�T�C�������gID
             p.last_update_date AS j_update_date,                   -- �]�ƈ��}�X�^.�ŏI�X�V��
-- 2016/02/24 Ver1.2 Mod Start
--             a.last_update_date AS a_update_date                    -- �A�T�C�������g�}�X�^.�ŏI�X�V��
             a.last_update_date AS a_update_date,                   -- �A�T�C�������g�}�X�^.�ŏI�X�V��
             p.attribute11      AS attribute11,                     -- �E�ʃR�[�h�i�V�j
             p.attribute13      AS attribute13,                     -- �E�ʃR�[�h�i���j
             ( SELECT  SUBSTRB( hlb.address3, 1, 2 )
               FROM    hz_cust_accounts    hcab    -- �ڋq�}�X�^(���_)
                      ,hz_party_sites      hpsb    -- �p�[�e�B�T�C�g
                      ,hz_cust_acct_sites  hcasb   -- �ڋq�T�C�g
                      ,hz_locations        hlb     -- �ڋq���Ə�
               WHERE  hcab.account_number      = p.attribute28
               AND    hcab.customer_class_code = cv_customer_class_code_1 --���_
               AND    hcab.cust_account_id     = hcasb.cust_account_id
               AND    hcasb.party_site_id      = hpsb.party_site_id
               AND    hpsb.location_id         = hlb.location_id
             )                  AS area_code                         -- �n��R�[�h
-- 2016/02/24 Ver1.2 Mod End
    FROM     per_periods_of_service t,
             per_all_assignments_f a,
             per_all_people_f p,
             (SELECT   pp.person_id AS person_id,
                       MAX(pp.effective_start_date) as effective_start_date
              FROM     per_all_people_f pp
              WHERE    pp.current_emp_or_apl_flag = 'Y'
              GROUP BY pp.person_id) pp
    WHERE    pp.person_id = p.person_id
    AND      pp.effective_start_date = p.effective_start_date
-- 2009/09/09 Ver1.1 modify start by Y.Kuboshima
--    AND      (NVL(p.attribute3,' ') > gv_jyugyoin_kbn OR NVL(p.attribute3,' ') < gv_jyugyoin_kbn)
    AND      p.attribute3 IN (cv_jyugyoin_kbn_1, cv_jyugyoin_kbn_3)
-- 2009/09/09 Ver1.1 modify end by Y.Kuboshima
    AND      (a.ass_attribute17 IS NULL
             OR TO_CHAR(p.last_update_date,'YYYYMMDD HH24:MI:SS') > a.ass_attribute17
             OR TO_CHAR(a.last_update_date,'YYYYMMDD HH24:MI:SS') > a.ass_attribute17)
    AND      p.person_id = a.person_id
    AND      p.effective_start_date = a.effective_start_date
    AND      a.period_of_service_id = t.period_of_service_id
    ORDER BY p.employee_number
  ;
  -- �Ј��f�[�^(����(���J�o��)���s��)
  CURSOR get_r_data_cur
  IS
-- 2016/02/24 Ver1.2 Mod Start
--    SELECT   p.person_id AS person_id,                              -- �]�ƈ�ID
--             p.employee_number AS employee_number,                  -- �]�ƈ��ԍ�
    SELECT   p.employee_number AS employee_number,                  -- �]�ƈ��ԍ�
-- 2016/02/24 Ver1.2 Mod End
             p.effective_start_date AS effective_start_date,        -- ���ДN����
             t.actual_termination_date AS actual_termination_date,  -- �ސE�N����
             p.per_information18 AS per_information18,              -- ������
             p.per_information19 AS per_information19,              -- ������
-- 2016/02/24 Ver1.2 Del Start
--             p.last_name AS last_name,                              -- �J�i��
--             p.first_name AS first_name,                            -- �J�i��
-- 2016/02/24 Ver1.2 Del End
             p.attribute28 AS attribute28,                          -- �N�[����
             a.ass_attribute2 AS ass_attribute2,                    -- ���ߓ�
             a.ass_attribute17 AS ass_attribute17,                  -- �����A�g�p���t(���̋@)
             a.assignment_id AS assignment_id,                      -- �A�T�C�������gID
             p.last_update_date AS j_update_date,                   -- �]�ƈ��}�X�^.�ŏI�X�V��
-- 2016/02/24 Ver1.2 Mod Start
--             a.last_update_date AS a_update_date                    -- �A�T�C�������g�}�X�^.�ŏI�X�V��
             a.last_update_date AS a_update_date,                   -- �A�T�C�������g�}�X�^.�ŏI�X�V��
             p.attribute11      AS attribute11,                     -- �E�ʃR�[�h�i�V�j
             p.attribute13      AS attribute13,                     -- �E�ʃR�[�h�i���j
             ( SELECT  SUBSTRB( hlb.address3, 1, 2 )
               FROM    hz_cust_accounts    hcab    -- �ڋq�}�X�^(���_)
                      ,hz_party_sites      hpsb    -- �p�[�e�B�T�C�g
                      ,hz_cust_acct_sites  hcasb   -- �ڋq�T�C�g
                      ,hz_locations        hlb     -- �ڋq���Ə�
               WHERE  hcab.account_number      = p.attribute28
               AND    hcab.customer_class_code = cv_customer_class_code_1 --���_
               AND    hcab.cust_account_id     = hcasb.cust_account_id
               AND    hcasb.party_site_id      = hpsb.party_site_id
               AND    hpsb.location_id         = hlb.location_id
             )                  AS area_code                         -- �n��R�[�h
-- 2016/02/24 Ver1.2 Mod End
    FROM     per_periods_of_service t,
             per_all_assignments_f a,
             per_all_people_f p,
             (SELECT   pp.person_id AS person_id,
                       MAX(pp.effective_start_date) as effective_start_date
              FROM     per_all_people_f pp
              WHERE    pp.current_emp_or_apl_flag = 'Y'
              GROUP BY pp.person_id) pp
    WHERE    pp.person_id = p.person_id
    AND      pp.effective_start_date = p.effective_start_date
-- 2009/09/09 Ver1.1 modify start by Y.Kuboshima
--    AND      (NVL(p.attribute3,' ') > gv_jyugyoin_kbn OR NVL(p.attribute3,' ') < gv_jyugyoin_kbn)
    AND      p.attribute3 IN (cv_jyugyoin_kbn_1, cv_jyugyoin_kbn_3)
-- 2009/09/09 Ver1.1 modify end by Y.Kuboshima
    AND      (((gd_select_start_datetime <= p.last_update_date) AND (p.last_update_date <= gd_select_end_datetime))
             OR ((gd_select_start_datetime <= a.last_update_date) AND (a.last_update_date <= gd_select_end_datetime)))
    AND      p.person_id = a.person_id
    AND      p.effective_start_date = a.effective_start_date
    AND      a.period_of_service_id = t.period_of_service_id
    ORDER BY p.employee_number
  ;
-- 2016/03/24 Ver1.3 Add Start
  -- ���_���F�҃f�[�^
  CURSOR get_base_approver_cur(
     id_issue_date     DATE
    ,iv_base_code      VARCHAR2
  )
  IS
  SELECT xev.employee_number  employee_number
  FROM   xxcso_employees_v2   xev
        ,fnd_lookup_values flv
  WHERE  (
           (
             (TO_DATE(xev.issue_date, cv_date_format_yyyymmdd) <= TRUNC(id_issue_date))
             AND
             (xev.work_base_code_new = iv_base_code)
           )
           OR
           (
             (TO_DATE(xev.issue_date, cv_date_format_yyyymmdd) > TRUNC(id_issue_date))
             AND
             (xev.work_base_code_old = iv_base_code)
           )
         )
   AND   flv.lookup_type  =  cv_approve_code
   AND   flv.lookup_code  =  CASE
                               WHEN (TO_DATE(xev.issue_date, cv_date_format_yyyymmdd) <= TRUNC(id_issue_date)) THEN
                                 xev.position_code_new
                               ELSE
                                 xev.position_code_old
                             END
   AND   flv.enabled_flag =  cv_y
   AND   flv.language     =  ct_user_lang
   AND   gd_process_date  BETWEEN flv.start_date_active
                          AND     NVL( flv.end_date_active, gd_process_date )
  ORDER BY
         CASE
           WHEN (TO_DATE(xev.issue_date, cv_date_format_yyyymmdd) <= TRUNC(id_issue_date)) THEN
             xev.position_code_new
           ELSE
             xev.position_code_old
         END
        ,xev.employee_number
  ;
-- 2016/03/24 Ver1.3 Add End
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ���������v���V�[�W��(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';                  -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �t�@�C���I�[�v�����[�h
    cv_open_mode_w          CONSTANT VARCHAR2(10)  := 'w';           -- �㏑��
--
    -- *** ���[�J���ϐ� ***
    lb_fexists              BOOLEAN;              -- �t�@�C�������݂��邩�ǂ���
    ln_file_size            NUMBER;               -- �t�@�C���̒���
    ln_block_size           NUMBER;               -- �t�@�C���V�X�e���̃u���b�N�T�C�Y
--
    -- *** ���[�J���E�J�[�\�� ***
    --���̋@�����A�g�p�Ј��f�[�^�e�[�u�����b�N�p(������s��)
    CURSOR get_t_dispenser_cur IS
-- 2016/02/24 Ver1.2 Mod Start
--      SELECT   d.person_id
--      FROM     xxcmm_out_people_d_dispenser d,
--               per_periods_of_service t,
      SELECT   a.person_id
      FROM     per_periods_of_service t,
-- 2016/02/24 Ver1.2 Mod End
               per_all_assignments_f a,
               per_all_people_f p
-- 2009/09/09 Ver1.1 modify start by Y.Kuboshima
--      WHERE    (NVL(p.attribute3,' ') > gv_jyugyoin_kbn OR NVL(p.attribute3,' ') < gv_jyugyoin_kbn)
      WHERE    p.attribute3 IN (cv_jyugyoin_kbn_1, cv_jyugyoin_kbn_3)
-- 2009/09/09 Ver1.1 modify end by Y.Kuboshima
      AND      (a.ass_attribute17 IS NULL
               OR TO_CHAR(p.last_update_date,'YYYYMMDD HH24:MI:SS') > a.ass_attribute17
               OR TO_CHAR(a.last_update_date,'YYYYMMDD HH24:MI:SS') > a.ass_attribute17)
      AND      p.person_id = a.person_id
      AND      p.effective_start_date = a.effective_start_date
      AND      a.period_of_service_id = t.period_of_service_id
-- 2009/09/09 Ver1.1 modify start by Y.Kuboshima
--      AND      p.person_id = d.person_id
--      FOR UPDATE NOWAIT;
-- 2016/02/24 Ver1.2 Mod Start
--      AND      p.person_id = d.person_id(+)
--      FOR UPDATE OF a.person_id, d.person_id NOWAIT;
      FOR UPDATE OF a.person_id NOWAIT;
-- 2016/02/24 Ver1.2 Mod End
-- 2009/09/09 Ver1.1 modify end by Y.Kuboshima
    --���̋@�����A�g�p�Ј��f�[�^�e�[�u�����b�N�p(����(���J�o��)���s��)
    CURSOR get_r_dispenser_cur IS
-- 2016/02/24 Ver1.2 Mod Start
--      SELECT   d.person_id
--      FROM     xxcmm_out_people_d_dispenser d,
--               per_periods_of_service t,
      SELECT   a.person_id
      FROM     per_periods_of_service t,
-- 2016/02/24 Ver1.2 Mod End
               per_all_assignments_f a,
               per_all_people_f p
-- 2009/09/09 Ver1.1 modify start by Y.Kuboshima
--      WHERE    (NVL(p.attribute3,' ') > gv_jyugyoin_kbn OR NVL(p.attribute3,' ') < gv_jyugyoin_kbn)
      WHERE    p.attribute3 IN (cv_jyugyoin_kbn_1, cv_jyugyoin_kbn_3)
-- 2009/09/09 Ver1.1 modify end by Y.Kuboshima
      AND      (((gd_select_start_datetime <= p.last_update_date) AND (p.last_update_date <= gd_select_end_datetime))
               OR ((gd_select_start_datetime <= a.last_update_date) AND (a.last_update_date <= gd_select_end_datetime)))
      AND      p.person_id = a.person_id
      AND      p.effective_start_date = a.effective_start_date
      AND      a.period_of_service_id = t.period_of_service_id
-- 2009/09/09 Ver1.1 modify start by Y.Kuboshima
--      AND      p.person_id = d.person_id
--      FOR UPDATE NOWAIT;
-- 2016/02/24 Ver1.2 Mod Start
--      AND      p.person_id = d.person_id(+)
--      FOR UPDATE OF a.person_id, d.person_id NOWAIT;
      FOR UPDATE OF a.person_id NOWAIT;
-- 2016/02/24 Ver1.2 Mod End
-- 2009/09/09 Ver1.1 modify end by Y.Kuboshima
    --
-- 2009/09/09 Ver1.1 delete start by Y.Kuboshima
-- ���̋@�����A�g�l�Ј��f�[�^�e�[�u�����b�N�J�[�\���ŃA�T�C�����g�}�X�^�����b�N����̂ō폜
--    --�A�T�C�������g�}�X�^���b�N�p(������s��)
--    CURSOR get_t_assignment_cur IS
--      SELECT   a.assignment_id
--      FROM     per_periods_of_service t,
--               per_all_assignments_f a,
--               per_all_people_f p
--      WHERE    (NVL(p.attribute3,' ') > gv_jyugyoin_kbn OR NVL(p.attribute3,' ') < gv_jyugyoin_kbn)
--      AND      (a.ass_attribute17 IS NULL
--               OR TO_CHAR(p.last_update_date,'YYYYMMDD HH24:MI:SS') > a.ass_attribute17
--               OR TO_CHAR(a.last_update_date,'YYYYMMDD HH24:MI:SS') > a.ass_attribute17)
--      AND      p.person_id = a.person_id
--      AND      p.effective_start_date = a.effective_start_date
--      AND      a.period_of_service_id = t.period_of_service_id
--      FOR UPDATE NOWAIT;
--    --�A�T�C�������g�}�X�^���b�N�p(����(���J�o��)���s��)
--    CURSOR get_r_assignment_cur IS
--      SELECT   a.assignment_id
--      FROM     per_periods_of_service t,
--               per_all_assignments_f a,
--               per_all_people_f p
--      WHERE    (NVL(p.attribute3,' ') > gv_jyugyoin_kbn OR NVL(p.attribute3,' ') < gv_jyugyoin_kbn)
--      AND      (((gd_select_start_datetime <= p.last_update_date) AND (p.last_update_date <= gd_select_end_datetime))
--               OR ((gd_select_start_datetime <= a.last_update_date) AND (a.last_update_date <= gd_select_end_datetime)))
--      AND      p.person_id = a.person_id
--      AND      p.effective_start_date = a.effective_start_date
--      AND      a.period_of_service_id = t.period_of_service_id
--      FOR UPDATE NOWAIT;
-- 2009/09/09 Ver1.1 delete start by Y.Kuboshima-
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���̓p�����[�^�w��`�F�b�N(�I�����݂̂̎w��̓G���[)
    IF ((gv_date_from IS NULL) AND (gv_date_to IS NOT NULL)) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm                               -- 'XXCMM'
                      ,iv_name         => cv_msg_00218                                 -- ���̓p�����[�^�w��G���[
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ���s�t���O�̎擾
    IF (gv_date_from IS NULL) THEN
      -- ������s��
      gv_run_flg := cv_flg_t;
    ELSE
      -- ����(���J�o��)��
      gv_run_flg := cv_flg_r;
    END IF;
--
    -- =========================================================
    --  �Ɩ����t�̎擾
    -- =========================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                      ,iv_name         => cv_msg_00018             -- �Ɩ��������t�擾�G���[
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ============================================================
    --  �Œ�o��(���̓p�����[�^��)
    -- ============================================================
    -- ���̓p�����[�^
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                    ,iv_name         => cv_msg_00038           -- ���̓p�����[�^�o�̓��b�Z�[�W
                    ,iv_token_name1  => cv_tkn_param           -- �g�[�N��(PARAM)
                    ,iv_token_value1 => cv_tkn_param3          -- �p�����[�^��(���̓p�����[�^)
                    ,iv_token_name2  => cv_tkn_value           -- �g�[�N��(VALUE)
                    ,iv_token_value2 => gv_date_from || '.' || gv_date_to
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    -- �擾�J�n��
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                    ,iv_name         => cv_msg_00038           -- ���̓p�����[�^�o�̓��b�Z�[�W
                    ,iv_token_name1  => cv_tkn_param           -- �g�[�N��(PARAM)
                    ,iv_token_value1 => cv_tkn_param1          -- �p�����[�^��(�J�n��)
                    ,iv_token_name2  => cv_tkn_value           -- �g�[�N��(VALUE)
                    ,iv_token_value2 => gv_date_from
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    IF (gv_run_flg = cv_flg_t) THEN
      -- ������s��
      -- �擾�I����
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00038           -- ���̓p�����[�^�o�̓��b�Z�[�W
                      ,iv_token_name1  => cv_tkn_param           -- �g�[�N��(PARAM)
                      ,iv_token_value1 => cv_tkn_param2          -- �p�����[�^��(�I����)
                      ,iv_token_name2  => cv_tkn_value           -- �g�[�N��(VALUE)
                      ,iv_token_value2 => gv_date_to
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
      -- ��s�}��(���̓p�����[�^�̉�)
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      -- ���̓p�����[�^�o�̓t���O�Ɂu�o�͌�v���Z�b�g
      gv_param_output_flg := '1';
    ELSE
      -- ����(���J�o��)��
      gd_select_start_date := TO_DATE(gv_date_from,'YYYY/MM/DD');
      gd_select_start_datetime := TO_DATE(gv_date_from || '00:00:00','YYYY/MM/DD HH24:MI:SS');
      IF (gv_date_to IS NULL) THEN
        -- �Ɩ����t���Z�b�g
        gd_select_end_date := gd_process_date;
      ELSE
        gd_select_end_date := TO_DATE(gv_date_to,'YYYY/MM/DD');
      END IF;
      gd_select_end_datetime := TO_DATE(TO_CHAR(gd_select_end_date,'YYYY/MM/DD') || ' 23:59:59','YYYY/MM/DD HH24:MI:SS');
      -- �擾�I����
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00038           -- ���̓p�����[�^�o�̓��b�Z�[�W
                      ,iv_token_name1  => cv_tkn_param           -- �g�[�N��(PARAM)
                      ,iv_token_value1 => cv_tkn_param2          -- �p�����[�^��(�I����)
                      ,iv_token_name2  => cv_tkn_value           -- �g�[�N��(VALUE)
                      ,iv_token_value2 => TO_CHAR(gd_select_end_date,'YYYY/MM/DD')
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
      -- ��s�}��(���̓p�����[�^�̉�)
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      -- ���̓p�����[�^�o�̓t���O�Ɂu�o�͌�v���Z�b�g
      gv_param_output_flg := '1';
      --
      -- =========================================================
      --  �Ώۊ��Ԏw��`�F�b�N
      -- =========================================================
      IF (gd_select_start_date > gd_select_end_date) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                        ,iv_name         => cv_msg_00019         -- �Ώۊ��Ԏw��G���[
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      -- =========================================================
      --  �Ώۊ��Ԑ����`�F�b�N(�擾�J�n��)
      -- =========================================================
      IF (gd_select_start_date > gd_process_date) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                        ,iv_name         => cv_msg_00030         -- �Ώۊ��Ԑ����G���[
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      -- =========================================================
      --  �Ώۊ��Ԑ����`�F�b�N(�擾�I����)
      -- =========================================================
      IF (gd_select_end_date > gd_process_date) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                        ,iv_name         => cv_msg_00030           -- �Ώۊ��Ԑ����G���[
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- ============================================================
    --  �v���t�@�C���̎擾
    -- ============================================================
    gv_filepath := fnd_profile.value(cv_filepath);
    IF (gv_filepath IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                      ,iv_name         => cv_msg_00002             -- �v���t�@�C���擾�G���[
                      ,iv_token_name1  => cv_tkn_profile           -- �g�[�N��(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_filepath_nm       -- �v���t�@�C����(CSV�t�@�C���o�͐�)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    gv_filename := fnd_profile.value(cv_filename);
    IF (gv_filename IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                      ,iv_name         => cv_msg_00002             -- �v���t�@�C���擾�G���[
                      ,iv_token_name1  => cv_tkn_profile           -- �g�[�N��(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_filename_nm       -- �v���t�@�C����(CSV�t�@�C����)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- 2009/09/09 Ver1.1 delete start by Y.Kuboshima
--    gv_jyugyoin_kbn := fnd_profile.value(cv_jyugyoin_kbn);
--    IF (gv_jyugyoin_kbn IS NULL) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
--                      ,iv_name         => cv_msg_00002             -- �v���t�@�C���擾�G���[
--                      ,iv_token_name1  => cv_tkn_profile           -- �g�[�N��(NG_PROFILE)
--                      ,iv_token_value1 => cv_tkn_jyugoin_kbn_nm    -- �v���t�@�C����(�]�ƈ��敪�̃_�~�[�l)
--                     );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
-- 2009/09/09 Ver1.1 delete end by Y.Kuboshima
    -- ============================================================
    --  �Œ�o��(I/F�t�@�C������)
    -- ============================================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp             -- 'XXCCP'
                    ,iv_name         => cv_msg_05102               -- �t�@�C�����o�̓��b�Z�[�W
                    ,iv_token_name1  => cv_tkn_filename            -- �g�[�N��(FILE_NAME)
                    ,iv_token_value1 => gv_filename                -- �t�@�C����
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- =========================================================
    --  CSV�t�@�C�����݃`�F�b�N
    -- =========================================================
    UTL_FILE.FGETATTR(gv_filepath,
                      gv_filename,
                      lb_fexists,
                      ln_file_size,
                      ln_block_size);
    IF (lb_fexists = TRUE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00010           -- �t�@�C���쐬�ς݃G���[
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =========================================================
    --  �t�@�C���I�[�v��
    -- =========================================================
    BEGIN
      gf_file_hand := UTL_FILE.FOPEN(gv_filepath
                                    ,gv_filename
                                    ,cv_open_mode_w);
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                        ,iv_name         => cv_msg_00003           -- �t�@�C���p�X�s���G���[
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- =========================================================
    --  ���̋@�����A�g�p�Ј��f�[�^�e�[�u���̍s���b�N
    -- =========================================================
    BEGIN
      IF (gv_run_flg = cv_flg_t) THEN
        -- ������s��
        OPEN get_t_dispenser_cur;
        CLOSE get_t_dispenser_cur;
      ELSE
        -- ����(���J�o��)��
        OPEN get_r_dispenser_cur;
        CLOSE get_r_dispenser_cur;
      END IF;
    EXCEPTION
      -- �e�[�u�����b�N�G���[
      WHEN lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                        ,iv_name         => cv_msg_00008           -- ���b�N�擾NG���b�Z�[�W
                        ,iv_token_name1  => cv_tkn_table           -- �g�[�N��(NG_TABLE)
-- 2009/09/09 Ver1.1 modify start by Y.Kuboshima
--                        ,iv_token_value1 => cv_tkn_table_nm2       -- �e�[�u����(���̋@�����A�g�p�Ј��f�[�^�e�[�u��)
-- 2016/02/24 Ver1.2 Mod Start
--                        ,iv_token_value1 => cv_tkn_table_nm1 || cv_tkn_table_nm2 -- �e�[�u����(�A�T�C�����g�}�X�^�A���̋@�����A�g�p�Ј��f�[�^�e�[�u��)
                        ,iv_token_value1 => cv_tkn_table_nm1       -- �e�[�u����(�A�T�C�����g�}�X�^)
-- 2016/02/24 Ver1.2 Mod End
-- 2009/09/09 Ver1.1 modify end by Y.Kuboshima
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
-- 2009/09/09 Ver1.1 delete start by Y.Kuboshima
--    -- =========================================================
--    --  �A�T�C�������g�}�X�^�̍s���b�N
--    -- =========================================================
--    BEGIN
--      IF (gv_run_flg = cv_flg_t) THEN
--        -- ������s��
--        OPEN get_t_assignment_cur;
--        CLOSE get_t_assignment_cur;
--      ELSE
--        -- ����(���J�o��)��
--        OPEN get_r_assignment_cur;
--        CLOSE get_r_assignment_cur;
--      END IF;
--    EXCEPTION
--      -- �e�[�u�����b�N�G���[
--      WHEN lock_expt THEN
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
--                        ,iv_name         => cv_msg_00008           -- ���b�N�擾NG���b�Z�[�W
--                        ,iv_token_name1  => cv_tkn_table           -- �g�[�N��(NG_TABLE)
--                        ,iv_token_value1 => cv_tkn_table_nm1       -- �e�[�u����(�A�T�C�������g�}�X�^)
--                       );
--        lv_errbuf := lv_errmsg;
--        RAISE global_api_expt;
--      WHEN OTHERS THEN
--        RAISE global_api_others_expt;
--    END;
-- 2009/09/09 Ver1.1 delete end by Y.Kuboshima
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_people_data
   * Description      : �Ј��f�[�^�擾�v���V�[�W��(A-2)
   ***********************************************************************************/
  PROCEDURE get_people_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_people_data';       -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    IF (gv_run_flg = cv_flg_t) THEN
      -- ������s��
      OPEN get_t_data_cur;
      <<t_data_loop>>
      LOOP
        FETCH get_t_data_cur BULK COLLECT INTO gt_data_tbl;
        EXIT WHEN get_t_data_cur%NOTFOUND;
      END LOOP t_data_loop;
      CLOSE get_t_data_cur;
    ELSE
      -- ����(���J�o��)��
      OPEN get_r_data_cur;
      <<r_data_loop>>
      LOOP
        FETCH get_r_data_cur BULK COLLECT INTO gt_data_tbl;
        EXIT WHEN get_r_data_cur%NOTFOUND;
      END LOOP r_data_loop;
      CLOSE get_r_data_cur;
    END IF;
    -- �Ώی������Z�b�g
    gn_target_cnt := gt_data_tbl.COUNT;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_people_data;
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : CSV�t�@�C���o�̓v���V�[�W��(A-4)
   ***********************************************************************************/
  PROCEDURE output_csv(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv';     -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_delimiter        CONSTANT VARCHAR2(1)  := ',';                -- CSV��؂蕶��
    cv_enclosed         CONSTANT VARCHAR2(2)  := '"';                -- �P��͂ݕ���
    cv_flg_m            CONSTANT VARCHAR2(1)  := 'M';                -- �����t���O(M:������)
    cv_flg_s            CONSTANT VARCHAR2(1)  := 'S';                -- �����t���O(S:�����ς�(���J�o����))
    cv_u                CONSTANT VARCHAR2(1)  := 'U';                -- �����敪(U:�Ώ�)
-- 2016/02/24 Ver1.2 Del Start
--    cv_i                CONSTANT VARCHAR2(1)  := 'I';                -- �Ώۋ敪(I:�V�K�o�^)
--    cv_a                CONSTANT VARCHAR2(1)  := 'A';                -- �Ώۋ敪(A:�����Ȃ�)
-- 2016/02/24 Ver1.2 Del End
    cv_o                CONSTANT VARCHAR2(1)  := 'O';                -- �����敪(O:���Ώ�)
-- 2016/02/24 Ver1.2 Del Start
--    cv_0                CONSTANT VARCHAR2(1)  := '0';                -- �A�g�t���O(0:�O��A�g�Ȃ�(�Ώۋ敪�F�����Ȃ�))
--    cv_1                CONSTANT VARCHAR2(1)  := '1';                -- �A�g�t���O(1:�O��A�g����(�Ώۋ敪�F�X�V�A�V�K�o�^))
-- 2016/02/24 Ver1.2 Del End
-- 2016/02/24 Ver1.2 Add Start
   cv_position_code_0   CONSTANT VARCHAR2(1)  := '0';                -- �����R�[�h:0
   cv_position_code_1   CONSTANT VARCHAR2(1)  := '1';                -- �����R�[�h:1
-- 2016/02/24 Ver1.2 Add End
--
    -- *** ���[�J���ϐ� ***
    ln_loop_cnt              NUMBER;                   -- ���[�v�J�E���^
    lv_csv_text              VARCHAR2(32000);          -- �o�͂P�s��������ϐ�
    lv_ret_flg               VARCHAR2(1);              -- �����t���O(M:�������AS:�����ς�(���J�o����))
    lv_chk_employee_number   VARCHAR2(22);             -- �]�ƈ��ԍ��d���`�F�b�N�p
    ln_o_cnt                 NUMBER;                   -- �����Ȃ��A���Ώۂ̌���(�Ώی����Ɋ܂܂Ȃ�)
    lv_kbn                   VARCHAR2(1);              -- �����敪
-- 2016/02/24 Ver1.2 Del Start
--    lv_end_date              VARCHAR2(8);              -- �K�p�I����
--    ln_stop_flg              NUMBER(1);                -- ���p��~�t���O
-- 2016/02/24 Ver1.2 Del End
    lv_skip_flg              VARCHAR2(1);              -- �X�L�b�v�t���O�p
-- 2016/02/24 Ver1.2 Add Start
    lv_del_flg               VARCHAR2(1);                               -- �폜�t���O
    lv_approve_flg           VARCHAR2(1);                               -- ���F�҃R�[�h���݃t���O
    lv_position_code_flg     VARCHAR2(1);                               -- ��E�R�[�h
    lt_position_code         fnd_lookup_values.lookup_code%TYPE;        -- �E�ʃR�[�h
-- 2016/03/24 Ver1.3 Del Start
--    lt_position_code_new     xxcso_employees_v2.position_code_new%TYPE; -- �E�ʃR�[�h�i�V�j
--    lt_position_code_old     xxcso_employees_v2.position_code_old%TYPE; -- �E�ʃR�[�h�i���j
-- 2016/03/24 Ver1.3 Del End
    ld_announce_date_check   DATE;                                      -- ���ߓ����f�p���t
    ln_authorizer_count      NUMBER;                                    -- ���F�Ґ�
-- 2016/02/24 Ver1.2 Add End
-- 2016/02/24 Ver1.2 Del Start
--    -- ���̋@�����A�g�p�Ј��f�[�^�i�[�p
--    lv_employee_number       xxcmm_out_people_d_dispenser.employee_number%TYPE;
--    ld_effective_start_date  xxcmm_out_people_d_dispenser.effective_start_date%TYPE;
--    lv_per_information18     xxcmm_out_people_d_dispenser.per_information18%TYPE;
--    lv_per_information19     xxcmm_out_people_d_dispenser.per_information19%TYPE;
--    lv_last_name             xxcmm_out_people_d_dispenser.last_name%TYPE;
--    lv_first_name            xxcmm_out_people_d_dispenser.first_name%TYPE;
--    lv_location_code         xxcmm_out_people_d_dispenser.location_code%TYPE;
--    lv_announce_date         xxcmm_out_people_d_dispenser.announce_date%TYPE;
--    lv_out_flag              xxcmm_out_people_d_dispenser.out_flag%TYPE;
-- 2016/02/24 Ver1.2 Del End
-- 2016/02/24 Ver1.2 Add Start
    lt_approve_employee      per_people_f.employee_number%TYPE;         -- ���F��
-- 2016/02/24 Ver1.2 Add End
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    -- ������
    ln_o_cnt := 0;
    -- ������s��
    IF (gv_run_flg = cv_flg_t) THEN
      gd_select_end_date := gd_process_date;
      lv_ret_flg := cv_flg_m;
-- 2016/02/24 Ver1.2 Add Start
      -- ���ߓ����f�p���t�ɋƖ����t+1���Z�b�g
      ld_announce_date_check := gd_process_date + 1;
    -- ����(���J�o��)���s��
    ELSE
      -- ���ߓ����f�p���t�ɋƖ����t���Z�b�g
      ld_announce_date_check := gd_process_date;
-- 2016/02/24 Ver1.2 Add End
    END IF;
    --
    <<out_loop>>
    FOR ln_loop_cnt IN 1..gn_target_cnt LOOP
      IF (gv_run_flg = cv_flg_r) THEN
        --========================================
        -- ���J�o�����s���A�����t���O�擾(A-3-1)
        --========================================
        IF ((gd_select_start_datetime  <= gt_data_tbl(ln_loop_cnt).j_update_date)
          AND (gt_data_tbl(ln_loop_cnt).j_update_date <= gd_select_end_datetime)
          AND ((gt_data_tbl(ln_loop_cnt).ass_attribute17 IS NULL)
          OR  (TO_CHAR(gt_data_tbl(ln_loop_cnt).j_update_date,'YYYYMMDD HH24:MI:SS') > gt_data_tbl(ln_loop_cnt).ass_attribute17)))
        THEN
          -- �����t���O�Ɂu�������v���Z�b�g
          lv_ret_flg := cv_flg_m;
        ELSIF ((gd_select_start_datetime  <= gt_data_tbl(ln_loop_cnt).a_update_date)
          AND (gt_data_tbl(ln_loop_cnt).a_update_date <= gd_select_end_datetime)
          AND ((gt_data_tbl(ln_loop_cnt).ass_attribute17 IS NULL)
          OR  (TO_CHAR(gt_data_tbl(ln_loop_cnt).a_update_date,'YYYYMMDD HH24:MI:SS') > gt_data_tbl(ln_loop_cnt).ass_attribute17)))
        THEN
          -- �����t���O�Ɂu�������v���Z�b�g
          lv_ret_flg := cv_flg_m;
        ELSE
          -- �����t���O�Ɂu�����ς݁v���Z�b�g
          lv_ret_flg := cv_flg_s;
        END IF;
      END IF;
-- 2016/02/24 Ver1.2 Del Start
--      IF (lv_ret_flg = cv_flg_m) THEN
--        --========================================
--        -- �����t���O���u�������v�̏ꍇ
--        --   �ߋ��A�g�f�[�^�擾(A-3-2)
--        --   ���R�[�h���݃`�F�b�N(A-3-3)
--        --========================================
--        BEGIN
--          SELECT   employee_number,          -- �]�ƈ��ԍ�
--                   effective_start_date,     -- ���ДN����
--                   per_information18,        -- ������
--                   per_information19,        -- ������
--                   last_name,                -- �J�i��
--                   first_name,               -- �J�i��
--                   location_code,            -- �N�[����
--                   announce_date             -- ���ߓ�
--          INTO     lv_employee_number,
--                   ld_effective_start_date,
--                   lv_per_information18,
--                   lv_per_information19,
--                   lv_last_name,
--                   lv_first_name,
--                   lv_location_code,
--                   lv_announce_date
--          FROM     xxcmm_out_people_d_dispenser
--          WHERE    person_id = gt_data_tbl(ln_loop_cnt).person_id;
-- 2016/02/24 Ver1.2 Del End
          --
          --========================================
          -- ���ك`�F�b�N(A-3-4)
          --========================================
          IF (gt_data_tbl(ln_loop_cnt).actual_termination_date IS NULL) THEN
            -- �ސE�f�[�^�ȊO
-- 2016/02/24 Ver1.2 Mod Start
--            IF ((gt_data_tbl(ln_loop_cnt).employee_number <> lv_employee_number)             -- �]�ƈ��ԍ�
--              OR (gt_data_tbl(ln_loop_cnt).effective_start_date <> ld_effective_start_date)  -- ���ДN����
--              OR (gt_data_tbl(ln_loop_cnt).per_information18 <> lv_per_information18)        -- ������
--              OR (gt_data_tbl(ln_loop_cnt).per_information19 <> lv_per_information19)        -- ������
--              OR (gt_data_tbl(ln_loop_cnt).last_name <> lv_last_name)                        -- �J�i��
--              OR (gt_data_tbl(ln_loop_cnt).first_name <> lv_first_name)                      -- �J�i��
--              OR (gt_data_tbl(ln_loop_cnt).attribute28 <> lv_location_code)                  -- �N�[����
--              OR (gt_data_tbl(ln_loop_cnt).ass_attribute2 <> lv_announce_date))              -- ���ߓ�
--            THEN
--              -- �����敪�ɍX�V���Z�b�g
--              lv_kbn := cv_u;
--            ELSE
--              -- �����敪�ɍ����Ȃ����Z�b�g
--              lv_kbn := cv_a;
--            END IF;
            -- �����敪�ɑΏۂ��Z�b�g
            lv_kbn := cv_u;
-- 2016/02/24 Ver1.2 Mod End
          ELSE
            -- �ސE�f�[�^
            IF ((gd_select_end_date >= gt_data_tbl(ln_loop_cnt).actual_termination_date)
-- Ver1.4 Mod Start
--              AND (gt_data_tbl(ln_loop_cnt).ass_attribute17 <= TO_CHAR(gt_data_tbl(ln_loop_cnt).actual_termination_date,'YYYYMMDD') || '23:59:59'))
              AND ((gt_data_tbl(ln_loop_cnt).ass_attribute17 IS NULL)
              OR (gt_data_tbl(ln_loop_cnt).ass_attribute17 <= TO_CHAR(gt_data_tbl(ln_loop_cnt).actual_termination_date,'YYYYMMDD') || '23:59:59')))
-- Ver1.4 Mod End
            THEN
              -- �����敪�ɑΏۂ��Z�b�g
              lv_kbn := cv_u;
            ELSE
              -- �����敪�ɖ��Ώۂ��Z�b�g
              lv_kbn := cv_o;
            END IF;
          END IF;
-- 2016/02/24 Ver1.2 Del Start
--        EXCEPTION
--          WHEN NO_DATA_FOUND THEN
--            -- �����敪�ɐV�K�o�^���Z�b�g
--            lv_kbn := cv_i;
--          WHEN OTHERS THEN
--            RAISE global_api_others_expt;
--        END;
-- 2016/02/24 Ver1.2 Del End
        -- �����敪�����Ώۃf�[�^�̏ꍇ�A�����R�[�h�̓ǂݍ���
        IF (lv_kbn = cv_o) THEN
          --===============================================
          -- �����敪���u���Ώہv�̏ꍇ
          -- ���Ώی����̃J�E���g
          --===============================================
          ln_o_cnt := ln_o_cnt + 1;
        ELSE
-- 2016/02/24 Ver1.2 Del Start
--          -- �����敪���V�K�o�^�A�X�V�̏ꍇ�ACSV�t�@�C���o�́E���̋@�����A�g�p�Ј��f�[�^�X�V�����s
--          IF (lv_kbn = cv_a) THEN
--            --===============================================
--            -- �����敪���u�����Ȃ��v�̏ꍇ
--            -- ���Ώی����̃J�E���g
--            -- ���̋@�����A�g�p�Ј��f�[�^�̍X�V(A-5)
--            --  (�A�g�t���O��0:�A�g�Ȃ����Z�b�g)
--            -- �����A�g�p���t�X�V(�A�T�C�������g�}�X�^)(A-6)
--            --===============================================
--            ln_o_cnt := ln_o_cnt + 1;
--            --===============================================
--            -- ���̋@�����A�g�p�Ј��f�[�^�X�V(A-5)
--            --===============================================
--            BEGIN
--              UPDATE   xxcmm_out_people_d_dispenser
--              SET      out_flag = cv_0
--              WHERE    person_id = gt_data_tbl(ln_loop_cnt).person_id;
--            EXCEPTION
--              WHEN OTHERS THEN
--                lv_errmsg := xxcmn_common_pkg.get_msg(
--                                 iv_application  => cv_msg_kbn_cmm                           -- 'XXCMM'
--                                ,iv_name         => cv_msg_00032                             -- ���̋@�����A�g�p�Ј��e�[�u���X�V�G���[
--                                ,iv_token_name1  => cv_tkn_word                              -- �g�[�N��(NG_WORD)
--                                ,iv_token_value1 => cv_tkn_word1                             -- NG_WORD
--                                ,iv_token_name2  => cv_tkn_data                              -- �g�[�N��(NG_DATA)
--                                ,iv_token_value2 => gt_data_tbl(ln_loop_cnt).employee_number -- NG_WORD��DATA
--                               );
--                lv_errbuf := lv_errmsg;
--                RAISE global_api_expt;
--            END;
--            --===============================================
--            -- �����A�g�p���t�X�V(�A�T�C�������g�}�X�^)(A-6)
--            --===============================================
--            BEGIN
--              UPDATE   per_all_assignments_f
--              SET      ass_attribute17 = TO_CHAR(SYSDATE,'YYYYMMDD HH24:MI:SS')
--              WHERE    assignment_id = gt_data_tbl(ln_loop_cnt).assignment_id
--              AND      effective_start_date = gt_data_tbl(ln_loop_cnt).effective_start_date;
--            EXCEPTION
--              WHEN OTHERS THEN
--                lv_errmsg := xxcmn_common_pkg.get_msg(
--                                 iv_application  => cv_msg_kbn_cmm                           -- 'XXCMM'
--                                ,iv_name         => cv_msg_00029                             -- �A�T�C�������g�}�X�^�X�V�G���[
--                                ,iv_token_name1  => cv_tkn_word                              -- �g�[�N��(NG_WORD)
--                                ,iv_token_value1 => cv_tkn_word1                             -- NG_WORD
--                                ,iv_token_name2  => cv_tkn_data                              -- �g�[�N��(NG_DATA)
--                                ,iv_token_value2 => gt_data_tbl(ln_loop_cnt).employee_number -- NG_WORD��DATA
--                               );
--                lv_errbuf := lv_errmsg;
--                RAISE global_api_expt;
--            END;
--          ELSE
-- 2016/02/24 Ver1.2 Del End
            --===============================================
            -- �]�ƈ��ԍ��d���`�F�b�N(A-3-5)
            --  (�d���f�[�^�����݂����ꍇ�A�x�����b�Z�[�W��\�����A�����p��)
            -- �֑������`�F�b�N(A-3-6)
            --  �Ώ�:�]�ƈ��ԍ��A����(����)�A�N�[����
            --  �֑����������݂����ꍇ�A�x�����b�Z�[�W��\�����ăX�L�b�v�ɃJ�E���g���A�����R�[�h�̓ǂݍ���
            --  �֑����������݂��Ȃ������ꍇ�A�����p��
            -- �����A�g�p���t�X�V(�A�T�C�������g�}�X�^)(A-6)
            -- ���팏���̃J�E���g
            --===============================================
            -- �X�L�b�v�t���O���N���A
            lv_skip_flg := '0';
            --========================================
            -- �]�ƈ��ԍ��d���`�F�b�N(A-3-5)
            --========================================
            -- �]�ƈ��ԍ����d�����Ă���ꍇ�A�x�����b�Z�[�W��\��
            IF (lv_chk_employee_number = SUBSTRB(gt_data_tbl(ln_loop_cnt).employee_number,1,5)) THEN
              IF (gv_warn_flg = '0') THEN
                -- �x���t���O�ɃI�����Z�b�g
                gv_warn_flg := '1';
                -- ��s�}��(���̓p�����[�^�̉�)
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => ''
                );
              END IF;
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cmm                             -- 'XXCMM'
                              ,iv_name         => cv_msg_00209                               -- �]�ƈ��ԍ��d�����b�Z�[�W
                              ,iv_token_name1  => cv_tkn_word                                -- �g�[�N��(NG_WORD)
                              ,iv_token_value1 => cv_tkn_word1                               -- NG_WORD
                              ,iv_token_name2  => cv_tkn_data                                -- �g�[�N��(NG_DATA)
                              ,iv_token_value2 => gt_data_tbl(ln_loop_cnt).employee_number   -- NG_WORD��DATA
                                                    || cv_tkn_word2
                                                    || SUBSTRB(gt_data_tbl(ln_loop_cnt).per_information18
                                                    || '�@'
                                                    || gt_data_tbl(ln_loop_cnt).per_information19,1,20)
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg
              );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg
              );
            END IF;
            --========================================
            -- �֑������`�F�b�N(A-3-6)
            --========================================
            -- �]�ƈ��ԍ�
            IF (xxccp_common_pkg2.chk_moji(gt_data_tbl(ln_loop_cnt).employee_number,cv_chk_cd) = FALSE) THEN
              IF (gv_warn_flg = '0') THEN
                -- �x���t���O�ɃI�����Z�b�g
                gv_warn_flg := '1';
                -- ��s�}��(���̓p�����[�^�̉�)
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => ''
                );
              END IF;
              -- �X�L�b�v�t���O���I���ɃZ�b�g
              lv_skip_flg := '1';
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cmm                             -- 'XXCMM'
                              ,iv_name         => cv_msg_00216                               -- �֑��������݃`�F�b�N���b�Z�[�W
                              ,iv_token_name1  => cv_tkn_ng_value                            -- �g�[�N��(NG_VALUE)
                              ,iv_token_value1 => cv_tkn_value_nm1                           -- NG_VALUE(�Ј��ԍ�)
                              ,iv_token_name2  => cv_tkn_word                                -- �g�[�N��(NG_WORD)
                              ,iv_token_value2 => cv_tkn_word1                               -- NG_WORD
                              ,iv_token_name3  => cv_tkn_data                                -- �g�[�N��(NG_DATA)
                              ,iv_token_value3 => gt_data_tbl(ln_loop_cnt).employee_number   -- NG_WORD��DATA
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg
              );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg
              );
            END IF;
-- 2016/02/24 Ver1.2 Del Start
--            -- ���ߓ�
--            IF (xxccp_common_pkg2.chk_moji(gt_data_tbl(ln_loop_cnt).ass_attribute2,cv_chk_cd) = FALSE) THEN
--              IF (gv_warn_flg = '0') THEN
--                -- �x���t���O�ɃI�����Z�b�g
--                gv_warn_flg := '1';
--                -- ��s�}��(���̓p�����[�^�̉�)
--                FND_FILE.PUT_LINE(
--                   which  => FND_FILE.LOG
--                  ,buff   => ''
--                );
--              END IF;
--              -- �X�L�b�v�t���O���I���ɃZ�b�g
--              lv_skip_flg := '1';
--              lv_errmsg := xxccp_common_pkg.get_msg(
--                               iv_application  => cv_msg_kbn_cmm                             -- 'XXCMM'
--                              ,iv_name         => cv_msg_00216                               -- �֑��������݃`�F�b�N���b�Z�[�W
--                              ,iv_token_name1  => cv_tkn_ng_value                            -- �g�[�N��(NG_VALUE)
--                              ,iv_token_value1 => cv_tkn_value_nm2                           -- NG_VALUE(���ߓ�)
--                              ,iv_token_name2  => cv_tkn_word                                -- �g�[�N��(NG_WORD)
--                              ,iv_token_value2 => cv_tkn_word1                               -- NG_WORD
--                              ,iv_token_name3  => cv_tkn_data                                -- �g�[�N��(NG_DATA)
--                              ,iv_token_value3 => gt_data_tbl(ln_loop_cnt).employee_number   -- NG_WORD��DATA
--                             );
--              FND_FILE.PUT_LINE(
--                 which  => FND_FILE.OUTPUT
--                ,buff   => lv_errmsg
--              );
--              FND_FILE.PUT_LINE(
--                 which  => FND_FILE.LOG
--                ,buff   => lv_errmsg
--              );
--            END IF;
-- 2016/02/24 Ver1.2 Del End
            -- ����(��)
            IF (xxccp_common_pkg2.chk_moji(gt_data_tbl(ln_loop_cnt).per_information18,cv_chk_cd) = FALSE) THEN
              IF (gv_warn_flg = '0') THEN
                -- �x���t���O�ɃI�����Z�b�g
                gv_warn_flg := '1';
                -- ��s�}��(���̓p�����[�^�̉�)
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => ''
                );
              END IF;
              -- �X�L�b�v�t���O���I���ɃZ�b�g
              lv_skip_flg := '1';
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cmm                             -- 'XXCMM'
                              ,iv_name         => cv_msg_00216                               -- �֑��������݃`�F�b�N���b�Z�[�W
                              ,iv_token_name1  => cv_tkn_ng_value                            -- �g�[�N��(NG_VALUE)
                              ,iv_token_value1 => cv_tkn_value_nm3                           -- NG_VALUE(����(��))
                              ,iv_token_name2  => cv_tkn_word                                -- �g�[�N��(NG_WORD)
                              ,iv_token_value2 => cv_tkn_word1                               -- NG_WORD
                              ,iv_token_name3  => cv_tkn_data                                -- �g�[�N��(NG_DATA)
                              ,iv_token_value3 => gt_data_tbl(ln_loop_cnt).employee_number   -- NG_WORD��DATA
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg
              );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg
              );
            END IF;
            -- ����(��)
            IF (xxccp_common_pkg2.chk_moji(gt_data_tbl(ln_loop_cnt).per_information19,cv_chk_cd) = FALSE) THEN
              IF (gv_warn_flg = '0') THEN
                -- �x���t���O�ɃI�����Z�b�g
                gv_warn_flg := '1';
                -- ��s�}��(���̓p�����[�^�̉�)
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => ''
                );
              END IF;
              -- �X�L�b�v�t���O���I���ɃZ�b�g
              lv_skip_flg := '1';
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cmm                             -- 'XXCMM'
                              ,iv_name         => cv_msg_00216                               -- �֑��������݃`�F�b�N���b�Z�[�W
                              ,iv_token_name1  => cv_tkn_ng_value                            -- �g�[�N��(NG_VALUE)
                              ,iv_token_value1 => cv_tkn_value_nm6                           -- NG_VALUE(����(��))
                              ,iv_token_name2  => cv_tkn_word                                -- �g�[�N��(NG_WORD)
                              ,iv_token_value2 => cv_tkn_word1                               -- NG_WORD
                              ,iv_token_name3  => cv_tkn_data                                -- �g�[�N��(NG_DATA)
                              ,iv_token_value3 => gt_data_tbl(ln_loop_cnt).employee_number   -- NG_WORD��DATA
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg
              );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg
              );
            END IF;
-- 2016/02/24 Ver1.2 Del Start
--            -- �J�i(��)
--            IF (xxccp_common_pkg2.chk_moji(gt_data_tbl(ln_loop_cnt).last_name,cv_chk_cd) = FALSE) THEN
--              IF (gv_warn_flg = '0') THEN
--                -- �x���t���O�ɃI�����Z�b�g
--                gv_warn_flg := '1';
--                -- ��s�}��(���̓p�����[�^�̉�)
--                FND_FILE.PUT_LINE(
--                   which  => FND_FILE.LOG
--                  ,buff   => ''
--                );
--              END IF;
--              -- �X�L�b�v�t���O���I���ɃZ�b�g
--              lv_skip_flg := '1';
--              lv_errmsg := xxccp_common_pkg.get_msg(
--                               iv_application  => cv_msg_kbn_cmm                             -- 'XXCMM'
--                              ,iv_name         => cv_msg_00216                               -- �֑��������݃`�F�b�N���b�Z�[�W
--                              ,iv_token_name1  => cv_tkn_ng_value                            -- �g�[�N��(NG_VALUE)
--                              ,iv_token_value1 => cv_tkn_value_nm4                           -- NG_VALUE(�J�i(��))
--                              ,iv_token_name2  => cv_tkn_word                                -- �g�[�N��(NG_WORD)
--                              ,iv_token_value2 => cv_tkn_word1                               -- NG_WORD
--                              ,iv_token_name3  => cv_tkn_data                                -- �g�[�N��(NG_DATA)
--                              ,iv_token_value3 => gt_data_tbl(ln_loop_cnt).employee_number   -- NG_WORD��DATA
--                             );
--              FND_FILE.PUT_LINE(
--                 which  => FND_FILE.OUTPUT
--                ,buff   => lv_errmsg
--              );
--              FND_FILE.PUT_LINE(
--                 which  => FND_FILE.LOG
--                ,buff   => lv_errmsg
--              );
--            END IF;
--            -- �J�i(��)
--            IF (xxccp_common_pkg2.chk_moji(gt_data_tbl(ln_loop_cnt).first_name,cv_chk_cd) = FALSE) THEN
--              IF (gv_warn_flg = '0') THEN
--                -- �x���t���O�ɃI�����Z�b�g
--                gv_warn_flg := '1';
--                -- ��s�}��(���̓p�����[�^�̉�)
--                FND_FILE.PUT_LINE(
--                   which  => FND_FILE.LOG
--                  ,buff   => ''
--                );
--              END IF;
--              -- �X�L�b�v�t���O���I���ɃZ�b�g
--              lv_skip_flg := '1';
--              lv_errmsg := xxccp_common_pkg.get_msg(
--                               iv_application  => cv_msg_kbn_cmm                             -- 'XXCMM'
--                              ,iv_name         => cv_msg_00216                               -- �֑��������݃`�F�b�N���b�Z�[�W
--                              ,iv_token_name1  => cv_tkn_ng_value                            -- �g�[�N��(NG_VALUE)
--                              ,iv_token_value1 => cv_tkn_value_nm7                           -- NG_VALUE(�J�i(��))
--                              ,iv_token_name2  => cv_tkn_word                                -- �g�[�N��(NG_WORD)
--                              ,iv_token_value2 => cv_tkn_word1                               -- NG_WORD
--                              ,iv_token_name3  => cv_tkn_data                                -- �g�[�N��(NG_DATA)
--                              ,iv_token_value3 => gt_data_tbl(ln_loop_cnt).employee_number   -- NG_WORD��DATA
--                             );
--              FND_FILE.PUT_LINE(
--                 which  => FND_FILE.OUTPUT
--                ,buff   => lv_errmsg
--              );
--              FND_FILE.PUT_LINE(
--                 which  => FND_FILE.LOG
--                ,buff   => lv_errmsg
--              );
--            END IF;
-- 2016/02/24 Ver1.2 Del End
            -- �N�[����
            IF (xxccp_common_pkg2.chk_moji(gt_data_tbl(ln_loop_cnt).attribute28,cv_chk_cd) = FALSE) THEN
              IF (gv_warn_flg = '0') THEN
                -- �x���t���O�ɃI�����Z�b�g
                gv_warn_flg := '1';
                -- ��s�}��(���̓p�����[�^�̉�)
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => ''
                );
              END IF;
              -- �X�L�b�v�t���O���I���ɃZ�b�g
              lv_skip_flg := '1';
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cmm                             -- 'XXCMM'
                              ,iv_name         => cv_msg_00216                               -- �֑��������݃`�F�b�N���b�Z�[�W
                              ,iv_token_name1  => cv_tkn_ng_value                            -- �g�[�N��(NG_VALUE)
                              ,iv_token_value1 => cv_tkn_value_nm5                           -- NG_VALUE(�N�[����)
                              ,iv_token_name2  => cv_tkn_word                                -- �g�[�N��(NG_WORD)
                              ,iv_token_value2 => cv_tkn_word1                               -- NG_WORD
                              ,iv_token_name3  => cv_tkn_data                                -- �g�[�N��(NG_DATA)
                              ,iv_token_value3 => gt_data_tbl(ln_loop_cnt).employee_number   -- NG_WORD��DATA
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg
              );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg
              );
            END IF;
            IF (lv_skip_flg = '1') THEN
              --========================================
              -- �֑����������݂����ꍇ
              -- �X�L�b�v�����̃J�E���g
              --========================================
              gn_warn_cnt := gn_warn_cnt + 1;
            ELSE
              --========================================
              -- �֑����������݂��Ȃ������ꍇ
              -- �Ó����`�F�b�N(A-3-7)
              -- ���F�҃`�F�b�N(A-3-8)
              -- CSV�t�@�C���o��(A-4)
              -- �����A�g�p���t�X�V(�A�T�C�������g�}�X�^)(A-6)
              -- ���팏���̃J�E���g
              --========================================
-- 2016/02/24 Ver1.2 Del Start
--              -- �K�p�I�����̎擾
--              IF (gt_data_tbl(ln_loop_cnt).ass_attribute2 = TO_CHAR(gt_data_tbl(ln_loop_cnt).effective_start_date,'YYYYMMDD')) THEN
--                lv_end_date := cv_99999999;
--              ELSE
--                lv_end_date := NULL;
--              END IF;
-- 2016/02/24 Ver1.2 Del End
              -- �폜�t���O�̎擾
              IF (gt_data_tbl(ln_loop_cnt).actual_termination_date IS NULL) THEN
-- 2016/02/24 Ver1.2 Mod Start
--                ln_stop_flg := cv_flg_0;
                lv_del_flg := cv_del_flg_0;
-- 2016/02/24 Ver1.2 Mod End
              ELSE
                IF ((gd_select_end_date >= gt_data_tbl(ln_loop_cnt).actual_termination_date)
                  AND ((gt_data_tbl(ln_loop_cnt).ass_attribute17 IS NULL)
                  OR (gt_data_tbl(ln_loop_cnt).ass_attribute17 <= TO_CHAR(gt_data_tbl(ln_loop_cnt).actual_termination_date,'YYYYMMDD') || '23:59:59')))
                THEN
-- 2016/02/24 Ver1.2 Mod Start
--                  ln_stop_flg := cv_flg_1;
                  lv_del_flg := cv_del_flg_1;
-- 2016/02/24 Ver1.2 Mod End
                ELSE
-- 2016/02/24 Ver1.2 Mod Start
--                  ln_stop_flg := cv_flg_0;
                  lv_del_flg := cv_del_flg_0;
-- 2016/02/24 Ver1.2 Mod End
                END IF;
              END IF;
-- 2016/02/24 Ver1.2 Add Start
--
              --========================================
              -- �Ó����`�F�b�N(A-3-7)
              --========================================
              -- ���ߓ�<=���ߓ����f�p���t�̎��A�E�ʃR�[�h�i�V�j���Z�b�g
              IF (TO_DATE(gt_data_tbl(ln_loop_cnt).ass_attribute2, cv_date_format_yyyymmdd) <= TRUNC(ld_announce_date_check)) THEN
                lt_position_code     := gt_data_tbl(ln_loop_cnt).attribute11;
-- 2016/03/24 Ver1.3 Del Start
--                lt_position_code_new := gt_data_tbl(ln_loop_cnt).attribute11;
--                lt_position_code_old := gt_data_tbl(ln_loop_cnt).attribute11;
-- 2016/03/24 Ver1.3 Del End
              -- ���ߓ�>���ߓ����f�p���t�̎��A�E�ʃR�[�h�i���j���Z�b�g
              ELSIF (TO_DATE(gt_data_tbl(ln_loop_cnt).ass_attribute2, cv_date_format_yyyymmdd) > TRUNC(ld_announce_date_check)) THEN
                lt_position_code     := gt_data_tbl(ln_loop_cnt).attribute13;
-- 2016/03/24 Ver1.3 Del Start
--                lt_position_code_new := gt_data_tbl(ln_loop_cnt).attribute13;
--                lt_position_code_old := gt_data_tbl(ln_loop_cnt).attribute13;
-- 2016/03/24 Ver1.3 Del End
              END IF;
--
              -- ������
              lv_approve_flg      := cv_n;
--
              -- ���F�҃R�[�h���݃`�F�b�N
              BEGIN
                SELECT cv_y  approve_flg
                INTO   lv_approve_flg
                FROM   fnd_lookup_values flv  -- �Q�ƃ^�C�v
                WHERE  flv.lookup_type  =  cv_approve_code
                AND    flv.lookup_code  =  lt_position_code
                AND    flv.enabled_flag =  cv_y
                AND    flv.language     =  ct_user_lang
                AND    gd_process_date  BETWEEN flv.start_date_active
                                        AND     NVL( flv.end_date_active, gd_process_date )
                ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  -- �擾�ł��Ȃ��ꍇ�A��E�R�[�h�F0
                  lv_position_code_flg := cv_position_code_0;
                WHEN OTHERS THEN
                  RAISE global_api_others_expt;
              END;
--
              --========================================
              -- ���F�҃`�F�b�N(A-3-8)
              --========================================
              IF ( lv_approve_flg = cv_y ) THEN
-- 2016/03/24 Ver1.3 Mod Start
--                BEGIN
--                  SELECT COUNT(0) authorizer_count
--                  INTO   ln_authorizer_count
--                  FROM   xxcso_employees_v2  xev
--                  WHERE  (
--                          (
--                           (TO_DATE(xev.issue_date, cv_date_format_yyyymmdd) <= TRUNC(ld_announce_date_check))
--                           AND
--                           (xev.work_base_code_new = gt_data_tbl(ln_loop_cnt).attribute28)
--                           AND
--                           (xev.position_code_new  = lt_position_code_new)
--                          )
--                          OR
--                          (
--                           (TO_DATE(xev.issue_date, cv_date_format_yyyymmdd) > TRUNC(ld_announce_date_check))
--                           AND
--                           (xev.work_base_code_old = gt_data_tbl(ln_loop_cnt).attribute28)
--                           AND
--                           (xev.position_code_old  = lt_position_code_old)
--                          )
--                         )
--                  ;
--                EXCEPTION
--                  WHEN OTHERS THEN
--                  RAISE global_api_others_expt;
--                END;
----
--                -- ���F�Ґ����������݂���ꍇ
--                IF ( ln_authorizer_count > 1 ) THEN
--                  lv_errmsg := xxccp_common_pkg.get_msg(
--                                   iv_application  => cv_msg_kbn_cmm                             -- 'XXCMM'
--                                  ,iv_name         => cv_msg_00224                               -- ���F�ҕ����x��
--                                  ,iv_token_name1  => cv_tkn_department_code                     -- �g�[�N��(DEPARTMENT_CODE)
--                                  ,iv_token_value1 => gt_data_tbl(ln_loop_cnt).attribute28       -- �N�[����
--                                  ,iv_token_name2  => cv_tkn_employee_number                     -- �g�[�N��(EMPLOYEE_NUMBER)
--                                  ,iv_token_value2 => gt_data_tbl(ln_loop_cnt).employee_number   -- �]�ƈ��ԍ�
--                                 );
--                  FND_FILE.PUT_LINE(
--                     which  => FND_FILE.OUTPUT
--                    ,buff   => lv_errmsg
--                  );
--                  -- �x���t���O�ɃI�����Z�b�g
--                  gv_warn_flg := '1';
--                  lv_position_code_flg := cv_position_code_0;
--                ELSE
--                  lv_position_code_flg := cv_position_code_1;
--                END IF;
                -- ���ɋ��_�P�ʂŏ��F�҂��擾���Ă���ꍇ
                IF ( gt_base_applover_tab.EXISTS(gt_data_tbl(ln_loop_cnt).attribute28) ) THEN
                  -- ���F�҂̔���
                  IF ( gt_base_applover_tab(gt_data_tbl(ln_loop_cnt).attribute28) = gt_data_tbl(ln_loop_cnt).employee_number ) THEN
                    lv_position_code_flg := cv_position_code_1;
                  ELSE
                    lv_position_code_flg := cv_position_code_0;
                  END IF;
                -- ���_�P�ʂŏ��F�҂��擾���Ă��Ȃ��ꍇ
                ELSE
                  -- ���_�̏��F��(�ŏ�ʂ̐E�ʎ�)���擾����
                  OPEN get_base_approver_cur(
                     ld_announce_date_check
                    ,gt_data_tbl(ln_loop_cnt).attribute28
                  );
                  FETCH get_base_approver_cur INTO lt_approve_employee;
                  CLOSE get_base_approver_cur;
--
                  -- ���_�̏��F�҂��擾�ł����ꍇ
                  IF ( lt_approve_employee IS NOT NULL ) THEN
                    -- �z��ɏ��F�҂��i�[
                    gt_base_applover_tab(gt_data_tbl(ln_loop_cnt).attribute28) := lt_approve_employee;
                    -- ���F�҂̔���
                    IF ( gt_base_applover_tab(gt_data_tbl(ln_loop_cnt).attribute28) = gt_data_tbl(ln_loop_cnt).employee_number ) THEN
                      lv_position_code_flg := cv_position_code_1;
                    ELSE
                      lv_position_code_flg := cv_position_code_0;
                    END IF;
                    -- ������
                    lt_approve_employee := NULL;
                  -- ���_�̏��F�҂��擾�ł��Ȃ��ꍇ
                  ELSE
                    -- ���b�Z�[�W����
                    lv_errmsg := xxccp_common_pkg.get_msg(
                                     iv_application  => cv_msg_kbn_cmm                             -- 'XXCMM'
                                    ,iv_name         => cv_msg_00224                               -- ���F�ҕ����x��
                                    ,iv_token_name1  => cv_tkn_employee_number                     -- �g�[�N��(EMPLOYEE_NUMBER)
                                    ,iv_token_value1 => gt_data_tbl(ln_loop_cnt).employee_number   -- �]�ƈ��ԍ�
                                    ,iv_token_name2  => cv_tkn_department_code                     -- �g�[�N��(DEPARTMENT_CODE)
                                    ,iv_token_value2 => gt_data_tbl(ln_loop_cnt).attribute28       -- �N�[����
                                   );
                    -- ���b�Z�[�W�o��
                    FND_FILE.PUT_LINE(
                       which  => FND_FILE.OUTPUT
                      ,buff   => lv_errmsg
                    );
                    --
                    gv_warn_flg          := '1';                -- �x���t���O�ɃI�����Z�b�g
                    lv_position_code_flg := cv_position_code_0; -- (HOST)��E�R�[�h:0(���F�҈ȊO)
                  END IF;
                END IF;
-- 2016/03/24 Ver1.3 Mod End
              END IF;
--
-- 2016/02/24 Ver1.2 Add End
-- 2016/02/24 Ver1.2 Mod Start
--              lv_csv_text := cv_enclosed || cv_riyou_kbn || cv_enclosed || cv_delimiter      -- ���p�ҋ敪
--                || cv_enclosed || SUBSTRB(gt_data_tbl(ln_loop_cnt).employee_number,1,5)      -- ���O�C��ID
--                || cv_enclosed || cv_delimiter
--                || SUBSTRB(gt_data_tbl(ln_loop_cnt).ass_attribute2,1,8) || cv_delimiter      -- �K�p�J�n��
--                || lv_end_date || cv_delimiter                                               -- �K�p�I����
--                || cv_enclosed || SUBSTRB(gt_data_tbl(ln_loop_cnt).per_information18         -- �]�ƈ�����
--                || '�@' || gt_data_tbl(ln_loop_cnt).per_information19,1,20)
--                || cv_enclosed || cv_delimiter
--                || cv_enclosed || SUBSTRB(gt_data_tbl(ln_loop_cnt).last_name                 -- �]�ƈ�����(�J�i)
--                || '�@' || gt_data_tbl(ln_loop_cnt).first_name,1,15)
--                || cv_enclosed || cv_delimiter
--                || cv_enclosed || SUBSTRB(gt_data_tbl(ln_loop_cnt).attribute28,1,4)          -- ���_�i����j�R�[�h
--                || cv_enclosed || cv_delimiter
--                || cv_enclosed || cv_team_cd || cv_enclosed || cv_delimiter                  -- �`�[���R�[�h
--                || NULL || cv_delimiter                                                      -- ����1
--                || NULL || cv_delimiter                                                      -- ����2
--                || NULL || cv_delimiter                                                      -- ����3
--                || NULL || cv_delimiter                                                      -- ����4
--                || NULL || cv_delimiter                                                      -- ����5
--                || NULL || cv_delimiter                                                      -- ����6
--                || NULL || cv_delimiter                                                      -- ����7
--                || ln_stop_flg || cv_delimiter                                               -- ���p��~�t���O
--                || cv_enclosed || NULL || cv_enclosed || cv_delimiter                        -- �쐬�S���҃R�[�h
--                || cv_enclosed || NULL || cv_enclosed || cv_delimiter                        -- �쐬�����R�[�h
--                || cv_enclosed || NULL || cv_enclosed || cv_delimiter                        -- �쐬�v���O����ID
--                || cv_enclosed || cv_tanto_cd || cv_enclosed || cv_delimiter                 -- �X�V�S���҃R�[�h
--                || cv_enclosed || cv_busyo_cd || cv_enclosed || cv_delimiter                 -- �X�V�����R�[�h
--                || cv_enclosed || cv_program_id || cv_enclosed || cv_delimiter               -- �X�V�v���O����ID
--                || NULL || cv_delimiter                                                      -- �쐬���������b
--                || NULL                                                                      -- �X�V���������b
              lv_csv_text := cv_enclosed || SUBSTRB(gt_data_tbl(ln_loop_cnt).employee_number,1,5)
                || cv_enclosed || cv_delimiter                                                    -- �c�ƒS��CD
                || cv_enclosed || SUBSTRB(gt_data_tbl(ln_loop_cnt).per_information18
                || '�@' || gt_data_tbl(ln_loop_cnt).per_information19,1,20)
                || cv_enclosed || cv_delimiter                                                    -- �c�ƒS����
                || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- (HOST)�S���Җ��J�i
                || cv_enclosed || gt_data_tbl(ln_loop_cnt).area_code
                || cv_enclosed || cv_delimiter                                                    -- �x�XCD
                || cv_enclosed || SUBSTRB(gt_data_tbl(ln_loop_cnt).attribute28,1,4)
                || cv_enclosed || cv_delimiter                                                    -- �c�Ə�CD
                || cv_enclosed || cv_department_flg_1 || cv_enclosed || cv_delimiter              -- (HOST)�P�ہE�Q�ۃt���O
                || cv_enclosed || cv_team_cd || cv_enclosed || cv_delimiter                       -- (HOST)�ۃR�[�h
                || cv_enclosed || lv_position_code_flg || cv_enclosed || cv_delimiter             -- (HOST)��E�R�[�h
                || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- ���ʋ敪
                || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- (HOST)���ДN����
                || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- (HOST)�Z�L�����e�B�G���A
                || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- (HOST)�p�X���[�h
                || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �z�X�g�f�[�^�o�^�N�����U��
                || cv_enclosed || NULL || cv_enclosed || cv_delimiter                             -- �z�X�g�f�[�^�X�V�N�����U��
                || cv_enclosed || lv_del_flg || cv_enclosed || cv_delimiter                       -- �폜�t���O
                || cv_enclosed || NULL || cv_enclosed                                             -- �ړ���
-- 2016/02/24 Ver1.2 Mod End
              ;
              BEGIN
                -- �t�@�C����������
                UTL_FILE.PUT_LINE(gf_file_hand,lv_csv_text);
              EXCEPTION
                -- �t�@�C���A�N�Z�X�����G���[
                WHEN UTL_FILE.INVALID_OPERATION THEN
                  lv_errmsg := xxcmn_common_pkg.get_msg(
                                   iv_application  => cv_msg_kbn_cmm                         -- 'XXCMM'
                                  ,iv_name         => cv_msg_00007                           -- �t�@�C���A�N�Z�X�����G���[
                                 );
                  lv_errbuf := lv_errmsg;
                  RAISE global_api_expt;
                --
                -- CSV�f�[�^�o�̓G���[
                WHEN UTL_FILE.WRITE_ERROR THEN
                  lv_errmsg := xxcmn_common_pkg.get_msg(
                                   iv_application  => cv_msg_kbn_cmm                         -- 'XXCMM'
                                  ,iv_name         => cv_msg_00009                           -- CSV�f�[�^�o�̓G���[
                                  ,iv_token_name1  => cv_tkn_word                            -- �g�[�N��(NG_WORD)
                                  ,iv_token_value1 => cv_tkn_word1                           -- NG_WORD
                                  ,iv_token_name2  => cv_tkn_data                            -- �g�[�N��(NG_DATA)
                                  ,iv_token_value2 => gt_data_tbl(ln_loop_cnt).employee_number -- NG_WORD��DATA
                                 );
                  lv_errbuf := lv_errmsg;
                  RAISE global_api_expt;
                WHEN OTHERS THEN
                  RAISE global_api_others_expt;
              END;
-- 2016/02/24 Ver1.2 Del Start
--              --========================================
--              -- ���̋@�����A�g�p�Ј��f�[�^�X�V(A-5)
--              --========================================
--              BEGIN
--                IF (lv_kbn = cv_i) THEN
--                -- �V�K�o�^
--                  INSERT
--                  INTO     xxcmm_out_people_d_dispenser( person_id                 -- �]�ƈ�ID
--                                                      ,employee_number             -- �]�ƈ��ԍ�
--                                                      ,effective_start_date        -- ���ДN����
--                                                      ,per_information18           -- ������
--                                                      ,per_information19           -- ������
--                                                      ,last_name                   -- �J�i��
--                                                      ,first_name                  -- �J�i��
--                                                      ,location_code               -- �N�[����
--                                                      ,announce_date               -- ���ߓ�
--                                                      ,out_flag)                   -- �A�g�t���O
--                  VALUES   ( gt_data_tbl(ln_loop_cnt).person_id
--                            ,gt_data_tbl(ln_loop_cnt).employee_number
--                            ,gt_data_tbl(ln_loop_cnt).effective_start_date
--                            ,gt_data_tbl(ln_loop_cnt).per_information18
--                            ,gt_data_tbl(ln_loop_cnt).per_information19
--                            ,gt_data_tbl(ln_loop_cnt).last_name
--                            ,gt_data_tbl(ln_loop_cnt).first_name
--                            ,gt_data_tbl(ln_loop_cnt).attribute28
--                            ,gt_data_tbl(ln_loop_cnt).ass_attribute2
--                            ,cv_1);
--                ELSE
--                  -- �X�V
--                  UPDATE   xxcmm_out_people_d_dispenser
--                  SET      employee_number = gt_data_tbl(ln_loop_cnt).employee_number,
--                           effective_start_date = gt_data_tbl(ln_loop_cnt).effective_start_date,
--                           per_information18 = gt_data_tbl(ln_loop_cnt).per_information18,
--                           per_information19 = gt_data_tbl(ln_loop_cnt).per_information19,
--                           last_name = gt_data_tbl(ln_loop_cnt).last_name,
--                           first_name = gt_data_tbl(ln_loop_cnt).first_name,
--                           location_code = gt_data_tbl(ln_loop_cnt).attribute28,
--                           announce_date = gt_data_tbl(ln_loop_cnt).ass_attribute2,
--                           out_flag = cv_1
--                  WHERE    person_id = gt_data_tbl(ln_loop_cnt).person_id;
--                END IF;
--              EXCEPTION
--                WHEN OTHERS THEN
--                  lv_errmsg := xxcmn_common_pkg.get_msg(
--                                   iv_application  => cv_msg_kbn_cmm               -- 'XXCMM'
--                                  ,iv_name         => cv_msg_00032                 -- ���̋@�����A�g�p�Ј��e�[�u���X�V�G���[
--                                  ,iv_token_name1  => cv_tkn_word                  -- �g�[�N��(NG_WORD)
--                                  ,iv_token_value1 => cv_tkn_word1                 -- NG_WORD
--                                  ,iv_token_name2  => cv_tkn_data                  -- �g�[�N��(NG_DATA)
--                                  ,iv_token_value2 => gt_data_tbl(ln_loop_cnt).employee_number -- NG_WORD��DATA
--                                 );
--                  lv_errbuf := lv_errmsg;
--                  RAISE global_api_expt;
--              END;
-- 2016/02/24 Ver1.2 Del End
              --===============================================
              -- �����A�g�p���t�X�V(�A�T�C�������g�}�X�^)(A-6)
              --===============================================
-- 2016/02/24 Ver1.2 Mod Start
--              BEGIN
--                UPDATE   per_all_assignments_f
--                SET      ass_attribute17 = TO_CHAR(SYSDATE,'YYYYMMDD HH24:MI:SS')
--                WHERE    assignment_id = gt_data_tbl(ln_loop_cnt).assignment_id
--                AND      effective_start_date = gt_data_tbl(ln_loop_cnt).effective_start_date;
--              EXCEPTION
--                WHEN OTHERS THEN
--                  lv_errmsg := xxcmn_common_pkg.get_msg(
--                                   iv_application  => cv_msg_kbn_cmm               -- 'XXCMM'
--                                  ,iv_name         => cv_msg_00029                 -- �A�T�C�������g�}�X�^�X�V�G���[
--                                  ,iv_token_name1  => cv_tkn_word                  -- �g�[�N��(NG_WORD)
--                                  ,iv_token_value1 => cv_tkn_word1                 -- NG_WORD
--                                  ,iv_token_name2  => cv_tkn_data                  -- �g�[�N��(NG_DATA)
--                                  ,iv_token_value2 => gt_data_tbl(ln_loop_cnt).employee_number -- NG_WORD��DATA
--                                 );
--                  lv_errbuf := lv_errmsg;
--                  RAISE global_api_expt;
--              END;
              -- �����t���O�u�������v�̏ꍇ
              IF (lv_ret_flg = cv_flg_m) THEN
                BEGIN
                  UPDATE   per_all_assignments_f
                  SET      ass_attribute17 = TO_CHAR(SYSDATE,'YYYYMMDD HH24:MI:SS')
                  WHERE    assignment_id = gt_data_tbl(ln_loop_cnt).assignment_id
                  AND      effective_start_date = gt_data_tbl(ln_loop_cnt).effective_start_date;
                EXCEPTION
                  WHEN OTHERS THEN
                    lv_errmsg := xxcmn_common_pkg.get_msg(
                                     iv_application  => cv_msg_kbn_cmm               -- 'XXCMM'
                                    ,iv_name         => cv_msg_00029                 -- �A�T�C�������g�}�X�^�X�V�G���[
                                    ,iv_token_name1  => cv_tkn_word                  -- �g�[�N��(NG_WORD)
                                    ,iv_token_value1 => cv_tkn_word1                 -- NG_WORD
                                    ,iv_token_name2  => cv_tkn_data                  -- �g�[�N��(NG_DATA)
                                    ,iv_token_value2 => gt_data_tbl(ln_loop_cnt).employee_number -- NG_WORD��DATA
                                   );
                    lv_errbuf := lv_errmsg;
                    RAISE global_api_expt;
                END;
              END IF;
-- 2016/02/24 Ver1.2 Mod End
              -- ���팏���̃J�E���g
              gn_normal_cnt := gn_normal_cnt + 1;
            END IF;
-- 2016/02/24 Ver1.2 Del Start
--          END IF;
-- 2016/02/24 Ver1.2 Del End
        END IF;
-- 2016/02/24 Ver1.2 Del Start
--      ELSE
--        --==============================================================
--        -- �����t���O���u�����ς݁v�̏ꍇ
--        -- �ߋ��A�g�f�[�^(�A�g�t���O)�擾(A-3-2)
--        -- �A�g�t���O��0:�A�g�Ȃ��̏ꍇ�A���Ώی����ɃJ�E���g���A�����R�[�h�̓ǂݍ���
--        -- �A�g�t���O��1:�A�g����̏ꍇ�A
--        --  �ސE�N�����ɒl�������Ă����ꍇ�A���p��~�t���O�Ɂu1�v���Z�b�g���ACSV�t�@�C���o��(A-4)
--        --  �ސE�N�����ɒl�������Ă��Ȃ������ꍇ�A���p��~�t���O�Ɂu0�v���Z�b�g�ACSV�t�@�C���o��(A-4)
--        -- ���̋@�����A�g�p�Ј��f�[�^�X�V(A-5)
--        --  (�A�g�t���O�ɂ�1:�A�g������Z�b�g)
--        -- �����A�g�p���t�X�V(�A�T�C�������g�}�X�^)(A-6)
--        -- ���팏���̃J�E���g
--        --==============================================================
--        BEGIN
--          SELECT   out_flag          -- �A�g�t���O
--          INTO     lv_out_flag
--          FROM     xxcmm_out_people_d_dispenser
--          WHERE    person_id = gt_data_tbl(ln_loop_cnt).person_id;
--        EXCEPTION
--          WHEN NO_DATA_FOUND THEN
--            lv_errmsg := xxcmn_common_pkg.get_msg(
--                             iv_application  => cv_msg_kbn_cmm                               -- 'XXCMM'
--                            ,iv_name         => cv_msg_00217                                 -- �ߋ��A�g�f�[�^�擾�G���[
--                            ,iv_token_name1  => cv_tkn_word                                  -- �g�[�N��(NG_WORD)
--                            ,iv_token_value1 => cv_tkn_word1                                 -- NG_WORD
--                            ,iv_token_name2  => cv_tkn_data                                  -- �g�[�N��(NG_DATA)
--                            ,iv_token_value2 => gt_data_tbl(ln_loop_cnt).employee_number     -- NG_WORD��DATA
--                           );
--            lv_errbuf := lv_errmsg;
--            RAISE global_api_expt;
--          WHEN OTHERS THEN
--            RAISE global_api_others_expt;
--        END;
--        -- �A�g�t���O��0�̏ꍇ�͑O��A�g�Ȃ��̂��߁A�����R�[�h�̓ǂݍ���
--        IF (lv_out_flag = cv_0) THEN
--          ln_o_cnt := ln_o_cnt + 1;
--        ELSE
--          --===============================================
--          -- �]�ƈ��ԍ��d���`�F�b�N(A-3-5)
--          --========================================
--          -- �]�ƈ��ԍ����d�����Ă���ꍇ�A�x�����b�Z�[�W��\��
--          IF (lv_chk_employee_number = SUBSTRB(gt_data_tbl(ln_loop_cnt).employee_number,1,5)) THEN
--            IF (gv_warn_flg = '0') THEN
--              -- �x���t���O�ɃI�����Z�b�g
--              gv_warn_flg := '1';
--              -- ��s�}��(���̓p�����[�^�̉�)
--              FND_FILE.PUT_LINE(
--                 which  => FND_FILE.LOG
--                ,buff   => ''
--              );
--            END IF;
--            lv_errmsg := xxccp_common_pkg.get_msg(
--                             iv_application  => cv_msg_kbn_cmm                             -- 'XXCMM'
--                            ,iv_name         => cv_msg_00209                               -- �]�ƈ��ԍ��d�����b�Z�[�W
--                            ,iv_token_name1  => cv_tkn_word                                -- �g�[�N��(NG_WORD)
--                            ,iv_token_value1 => cv_tkn_word1                               -- NG_WORD
--                            ,iv_token_name2  => cv_tkn_data                                -- �g�[�N��(NG_DATA)
--                            ,iv_token_value2 => gt_data_tbl(ln_loop_cnt).employee_number   -- NG_WORD��DATA
--                                                  || cv_tkn_word2
--                                                  || SUBSTRB(gt_data_tbl(ln_loop_cnt).per_information18
--                                                  || '�@'
--                                                  || gt_data_tbl(ln_loop_cnt).per_information19,1,20)
--                           );
--            FND_FILE.PUT_LINE(
--               which  => FND_FILE.OUTPUT
--              ,buff   => lv_errmsg
--            );
--            FND_FILE.PUT_LINE(
--               which  => FND_FILE.LOG
--              ,buff   => lv_errmsg
--            );
--          END IF;
--          --========================================
--          -- CSV�t�@�C���o��(A-4)
--          --========================================
--          -- �K�p�I�����̎擾
--          IF (gt_data_tbl(ln_loop_cnt).ass_attribute2 = TO_CHAR(gt_data_tbl(ln_loop_cnt).effective_start_date,'YYYYMMDD')) THEN
--            lv_end_date := cv_99999999;
--          ELSE
--            lv_end_date := NULL;
--          END IF;
--          -- ���p��~�t���O�̎擾
--          IF (gt_data_tbl(ln_loop_cnt).actual_termination_date IS NULL) THEN
--            ln_stop_flg := cv_flg_0;
--          ELSE
--            IF (gd_select_end_datetime >= gt_data_tbl(ln_loop_cnt).actual_termination_date) THEN
--              ln_stop_flg := cv_flg_1;
--            ELSE
--              ln_stop_flg := cv_flg_0;
--            END IF;
--          END IF;
--          lv_csv_text := cv_enclosed || cv_riyou_kbn || cv_enclosed || cv_delimiter          -- ���p�ҋ敪
--            || cv_enclosed || SUBSTRB(gt_data_tbl(ln_loop_cnt).employee_number,1,5)          -- ���O�C��ID
--            || cv_enclosed || cv_delimiter
--            || SUBSTRB(gt_data_tbl(ln_loop_cnt).ass_attribute2,1,8) || cv_delimiter          -- �K�p�J�n��
--            || lv_end_date || cv_delimiter                                                   -- �K�p�I����
--            || cv_enclosed || SUBSTRB(gt_data_tbl(ln_loop_cnt).per_information18             -- �]�ƈ�����
--            || '�@' || gt_data_tbl(ln_loop_cnt).per_information19,1,20)
--            || cv_enclosed || cv_delimiter
--            || cv_enclosed || SUBSTRB(gt_data_tbl(ln_loop_cnt).last_name                     -- �]�ƈ������i�J�i�j
--            || '�@' || gt_data_tbl(ln_loop_cnt).first_name,1,15)
--            || cv_enclosed || cv_delimiter
--            || cv_enclosed || SUBSTRB(gt_data_tbl(ln_loop_cnt).attribute28,1,4)              -- ���_�i����j�R�[�h
--            || cv_enclosed || cv_delimiter
--            || cv_enclosed || cv_team_cd || cv_enclosed || cv_delimiter                      -- �`�[���R�[�h
--            || NULL || cv_delimiter                                                          -- ����1
--            || NULL || cv_delimiter                                                          -- ����2
--            || NULL || cv_delimiter                                                          -- ����3
--            || NULL || cv_delimiter                                                          -- ����4
--            || NULL || cv_delimiter                                                          -- ����5
--            || NULL || cv_delimiter                                                          -- ����6
--            || NULL || cv_delimiter                                                          -- ����7
--            || ln_stop_flg || cv_delimiter                                                   -- ���p��~�t���O
--            || cv_enclosed || NULL || cv_enclosed || cv_delimiter                            -- �쐬�S���҃R�[�h
--            || cv_enclosed || NULL || cv_enclosed || cv_delimiter                            -- �쐬�����R�[�h
--            || cv_enclosed || NULL || cv_enclosed || cv_delimiter                            -- �쐬�v���O����ID
--            || cv_enclosed || cv_tanto_cd || cv_enclosed || cv_delimiter                     -- �X�V�S���҃R�[�h
--            || cv_enclosed || cv_busyo_cd || cv_enclosed || cv_delimiter                     -- �X�V�����R�[�h
--            || cv_enclosed || cv_program_id || cv_enclosed || cv_delimiter                   -- �X�V�v���O����ID
--            || NULL || cv_delimiter                                                          -- �쐬���������b
--            || NULL                                                                          -- �X�V���������b
--          ;
--          BEGIN
--            -- �t�@�C����������
--            UTL_FILE.PUT_LINE(gf_file_hand,lv_csv_text);
--          EXCEPTION
--            -- �t�@�C���A�N�Z�X�����G���[
--            WHEN UTL_FILE.INVALID_OPERATION THEN
--              lv_errmsg := xxcmn_common_pkg.get_msg(
--                               iv_application  => cv_msg_kbn_cmm                             -- 'XXCMM'
--                              ,iv_name         => cv_msg_00007                               -- �t�@�C���A�N�Z�X�����G���[
--                             );
--              lv_errbuf := lv_errmsg;
--              RAISE global_api_expt;
--            --
--            -- CSV�f�[�^�o�̓G���[
--            WHEN UTL_FILE.WRITE_ERROR THEN
--              lv_errmsg := xxcmn_common_pkg.get_msg(
--                               iv_application  => cv_msg_kbn_cmm                             -- 'XXCMM'
--                              ,iv_name         => cv_msg_00009                               -- CSV�f�[�^�o�̓G���[
--                              ,iv_token_name1  => cv_tkn_word                                -- �g�[�N��(NG_WORD)
--                              ,iv_token_value1 => cv_tkn_word1                               -- NG_WORD
--                              ,iv_token_name2  => cv_tkn_data                                -- �g�[�N��(NG_DATA)
--                              ,iv_token_value2 => gt_data_tbl(ln_loop_cnt).employee_number   -- NG_WORD��DATA
--                             );
--              lv_errbuf := lv_errmsg;
--              RAISE global_api_expt;
--            WHEN OTHERS THEN
--              RAISE global_api_others_expt;
--          END;
--          -- ���팏���̃J�E���g
--          gn_normal_cnt := gn_normal_cnt + 1;
--        END IF;
--      END IF;
-- 2016/02/24 Ver1.2 Del End
      lv_chk_employee_number := SUBSTRB(gt_data_tbl(ln_loop_cnt).employee_number,1,5);
    END LOOP u_out_loop;
    -- �Ώی����̎擾
    gn_target_cnt := gn_target_cnt - ln_o_cnt;
    --
    IF (gv_warn_flg = '1') THEN
      -- ��s�}��(�����������̏�A���邢�̓G���[���b�Z�[�W�̏�)
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_csv;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_warn_cnt   := 0;
    gn_error_cnt  := 0;
    gv_warn_flg   := '0';
    gv_param_output_flg := '0';
    --
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    --
    -- =============================================================
    --  ���������v���V�[�W��(A-1)
    -- =============================================================
    init(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =============================================================
    --  �Ј��f�[�^�擾�v���V�[�W��(A-2)
    -- =============================================================
    get_people_data(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =============================================================
    --  CSV�t�@�C���o�̓v���V�[�W��(A-4)
    -- =============================================================
    IF (gn_target_cnt > 0) THEN
      output_csv(
         lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
    --
    -- =====================================================
    --  �I�������v���V�[�W��(A-7)
    -- =====================================================
    -- CSV�t�@�C�����N���[�Y����
    UTL_FILE.FCLOSE(gf_file_hand);
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_date_from  IN  VARCHAR2,      --   1.�J�n��
    iv_date_to    IN  VARCHAR2       --   2.�I����
  )
--
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- ���̓p�����[�^�̎擾�A�`�F�b�N
    -- ===============================================
    gv_date_from := iv_date_from;
    gv_date_to := iv_date_to;
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      lv_errbuf   -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      --�G���[�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      -- ��s�}��(�G���[���b�Z�[�W�Ə����������̊�)
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      -- ���̓p�����[�^�o�͌�́A�G���[���b�Z�[�W�Ƃ̊Ԃɋ�s�}��
      IF (gv_param_output_flg = '1') THEN
        -- ��s�}��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => ''
        );
      END IF;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --�G���[���b�Z�[�W
      );
      -- �G���[�������A�e�����͈ȉ��ɓ��ꂵ�ďo�͂���
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
    ELSE
      IF (gv_warn_flg = '1') THEN
        --�x���̏ꍇ�A���^�[���E�R�[�h�Ɍx�����Z�b�g����
        lv_retcode := cv_status_warn;
      END IF;
    END IF;
    --
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --CSV�t�@�C�����N���[�Y����Ă��Ȃ������ꍇ�A�N���[�Y����
    IF (UTL_FILE.IS_OPEN(gf_file_hand)) THEN
      UTL_FILE.FCLOSE(gf_file_hand);
    END IF;
    --
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    ELSE
      COMMIT;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCMM002A02C;
/
