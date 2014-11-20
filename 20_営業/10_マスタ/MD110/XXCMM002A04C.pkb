CREATE OR REPLACE PACKAGE BODY XXCMM002A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM002A04C(body)
 * Description      : �Ј��f�[�^�A�g(�c�ƒ��[�V�X�e��)
 * MD.050           : �Ј��f�[�^�A�g(�c�ƒ��[�V�X�e��) MD050_CMM_002_A04
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ���������v���V�[�W��(A-1)
 *  get_people_data        �Ј��f�[�^�擾�v���V�[�W��(A-2)
 *  output_csv             CSV�t�@�C���o�̓v���V�[�W��(A-5)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/15    1.0   SCS ���� �M�q    ����쐬
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
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCMM002A04C';               -- �p�b�P�[�W��
  -- �v���t�@�C��
  cv_filepath               CONSTANT VARCHAR2(30)  := 'XXCMM1_CHOHYO_OUT_DIR';      -- �c�ƒ��[CSV�t�@�C���o�͐�
  cv_filename               CONSTANT VARCHAR2(30)  := 'XXCMM1_002A04_OUT_FILE';     -- �A�g�pCSV�t�@�C����
  cv_jyugyoin_kbn           CONSTANT VARCHAR2(30)  := 'XXCMM1_002A04_JYUGYOIN_KBN'; -- �]�ƈ��敪�̃_�~�[�l
  -- �g�[�N��
  cv_tkn_profile            CONSTANT VARCHAR2(10)  := 'NG_PROFILE';                 -- �v���t�@�C����
  cv_tkn_filepath_nm        CONSTANT VARCHAR2(20)  := 'CSV�t�@�C���o�͐�';
  cv_tkn_filename_nm        CONSTANT VARCHAR2(20)  := 'CSV�t�@�C����';
  cv_tkn_jyugoin_kbn_nm     CONSTANT VARCHAR2(20)  := '�]�ƈ��敪�̃_�~�[�l';
  cv_tkn_word               CONSTANT VARCHAR2(10)  := 'NG_WORD';                    -- ���ږ�
  cv_tkn_word1              CONSTANT VARCHAR2(10)  := '�Ј��ԍ�';
  cv_tkn_word2              CONSTANT VARCHAR2(10)  := 'CSV�w�b�_';
  cv_tkn_word3              CONSTANT VARCHAR2(10)  := '�A���� : ';
  cv_tkn_data               CONSTANT VARCHAR2(10)  := 'NG_DATA';                    -- �f�[�^
  cv_tkn_filename           CONSTANT VARCHAR2(10)  := 'FILE_NAME';                  -- �t�@�C����
  cv_tkn_param              CONSTANT VARCHAR2(10)  := 'PARAM';                      -- �p�����[�^��
  cv_tkn_param1             CONSTANT VARCHAR2(20)  := '�ŏI�X�V��(�J�n)';
  cv_tkn_param2             CONSTANT VARCHAR2(20)  := '�ŏI�X�V��(�I��)';
  cv_tkn_param3             CONSTANT VARCHAR2(20)  := '���̓p�����[�^';
  cv_tkn_value              CONSTANT VARCHAR2(10)  := 'VALUE';                      -- �p�����[�^�l
  cv_tkn_table              CONSTANT VARCHAR2(10)  := 'NG_TABLE';                   -- �e�[�u��
  cv_tkn_table_nm           CONSTANT VARCHAR2(20)  := '�A�T�C�������g�}�X�^';
  cv_tkn_kyoten             CONSTANT VARCHAR2(10)  := 'NG_KYOTEN';                  -- ���_�R�[�h(�V)
  -- ���b�Z�[�W�敪
  cv_msg_kbn_cmm            CONSTANT VARCHAR2(5)   := 'XXCMM';
  cv_msg_kbn_ccp            CONSTANT VARCHAR2(5)   := 'XXCCP';
  -- ���b�Z�[�W
  cv_msg_00038              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00038';           -- ���̓p�����[�^�o�̓��b�Z�[�W
  cv_msg_00002              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';           -- �v���t�@�C���擾�G���[
  cv_msg_05102              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-05102';           -- �t�@�C�����o�̓��b�Z�[�W
  cv_msg_00018              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00018';           -- �Ɩ����t�擾�G���[
  cv_msg_00030              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00030';           -- �Ώۊ��Ԑ����G���[
  cv_msg_00019              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00019';           -- �Ώۊ��Ԏw��G���[
  cv_msg_00010              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00010';           -- CSV�t�@�C�����݃`�F�b�N
  cv_msg_00003              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00003';           -- �t�@�C���p�X�s���G���[
  cv_msg_00008              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00008';           -- ���b�N�擾NG���b�Z�[�W
  cv_msg_00501              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00501';           -- AFF����G���[
  cv_msg_00205              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00205';           -- ���_�R�[�h(�V)�擾�G���[
  cv_msg_00209              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00209';           -- �]�ƈ��ԍ��d�����b�Z�[�W
  cv_msg_00007              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00007';           -- �t�@�C���A�N�Z�X�����G���[
  cv_msg_00009              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00009';           -- CSV�f�[�^�o�̓G���[
  cv_msg_00029              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00029';           -- �A�T�C�������g�}�X�^�X�V�G���[
  -- �Œ�l(CSV�w�b�_�A�ݒ�l)
  cv_nm1                    CONSTANT VARCHAR2(10)  := '�f�[�^��';
  cv_nm2                    CONSTANT VARCHAR2(10)  := '�t�@�C����';
  cv_nm3                    CONSTANT VARCHAR2(10)  := '�X�V�敪';
  cv_nm4                    CONSTANT VARCHAR2(20)  := '���_�i����j�R�[�h';
  cv_nm5                    CONSTANT VARCHAR2(12)  := '�Ζ��n�R�[�h';
  cv_nm6                    CONSTANT VARCHAR2(12)  := '��{���R�[�h';
  cv_nm7                    CONSTANT VARCHAR2(10)  := '�{���R�[�h';
  cv_nm8                    CONSTANT VARCHAR2(12)  := '�G���A�R�[�h';
  cv_nm9                    CONSTANT VARCHAR2(10)  := '�n��R�[�h';
  cv_nm10                   CONSTANT VARCHAR2(10)  := '�E�ʃR�[�h';
  cv_nm11                   CONSTANT VARCHAR2(14)  := '�E�ʕ����R�[�h';
  cv_nm12                   CONSTANT VARCHAR2(10)  := '�E�ʖ�';
  cv_nm13                   CONSTANT VARCHAR2(10)  := '�Ј��ԍ�';
  cv_nm14                   CONSTANT VARCHAR2(20)  := '�]�ƈ������i�J�i�j';
  cv_nm15                   CONSTANT VARCHAR2(20)  := '�]�ƈ������i�����j';
  cv_nm16                   CONSTANT VARCHAR2(10)  := '���N����';
  cv_nm17                   CONSTANT VARCHAR2(10)  := '���ʋ敪';
  cv_nm18                   CONSTANT VARCHAR2(10)  := '���ДN����';
  cv_nm19                   CONSTANT VARCHAR2(10)  := '�ސE�N����';
  cv_nm20                   CONSTANT VARCHAR2(20)  := '�ٓ����R�R�[�h';
  cv_nm21                   CONSTANT VARCHAR2(10)  := '�K�p�J�n��';
  cv_nm22                   CONSTANT VARCHAR2(10)  := '���i�R�[�h';
  cv_nm23                   CONSTANT VARCHAR2(10)  := '���i��';
  cv_nm24                   CONSTANT VARCHAR2(10)  := '�E��R�[�h';
  cv_nm25                   CONSTANT VARCHAR2(10)  := '�E�햼';
  cv_nm26                   CONSTANT VARCHAR2(10)  := '�E���R�[�h';
  cv_nm27                   CONSTANT VARCHAR2(10)  := '�E����';
  cv_nm28                   CONSTANT VARCHAR2(10)  := '���F�敪';
  cv_nm29                   CONSTANT VARCHAR2(10)  := '��s�敪';
  cv_nm30                   CONSTANT VARCHAR2(10)  := '�쐬�N����';
  cv_nm31                   CONSTANT VARCHAR2(10)  := '�ŏI�X�V��';
  cv_value1                 CONSTANT VARCHAR2(2)   := 'Z1';                         -- �f�[�^��
  cv_value2                 CONSTANT VARCHAR2(2)   := '00';                         -- �t�@�C����
  cv_value3_add             CONSTANT VARCHAR2(1)   := '1';                          -- �X�V�敪(�V�K�ǉ�)
  cv_value3_update          CONSTANT VARCHAR2(1)   := '2';                          -- �X�V�敪(�C���X�V)
  cv_value3_delete          CONSTANT VARCHAR2(1)   := '3';                          -- �X�V�敪(�폜)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �Ј��f�[�^���i�[���郌�R�[�h
  TYPE people_data_rec  IS RECORD(
       ass_attribute5   VARCHAR2(4),   -- ���_�i����j�R�[�h
       ass_attribute3   VARCHAR2(4),   -- �Ζ��n�R�[�h
       attribute11      VARCHAR2(3),   -- �E�ʃR�[�h
       ass_attribute11  VARCHAR2(2),   -- �E�ʕ����R�[�h
       attribute12      VARCHAR2(20),  -- �E�ʖ�
       employee_number  VARCHAR2(5),   -- �Ј��ԍ�
       kana             VARCHAR2(20),  -- �]�ƈ������i�J�i�j
       kanji            VARCHAR2(20),  -- �]�ƈ������i�����j
       sex              VARCHAR2(1),   -- ���ʋ敪
       start_date       VARCHAR2(8),   -- ���ДN����
       at_date          VARCHAR2(8),   -- �ސE�N����
       ass_attribute1   VARCHAR2(2),   -- �ٓ����R�R�[�h
       ass_attribute2   VARCHAR2(8),   -- �K�p�J�n��
       attribute7       VARCHAR2(3),   -- ���i�R�[�h
       attribute8       VARCHAR2(20),  -- ���i��
       attribute19      VARCHAR2(2),   -- �E��R�[�h
       attribute20      VARCHAR2(20),  -- �E�햼
       attribute15      VARCHAR2(3),   -- �E���R�[�h
       attribute16      VARCHAR2(20),  -- �E����
       ass_attribute13  VARCHAR2(7),   -- ���F�敪
       ass_attribute15  VARCHAR2(7),   -- ��s�敪
       assignment_id    NUMBER(10),    -- �A�T�C�������gID
       ass_attribute18  VARCHAR2(19),  -- �����A�g�p���t(���[)
       dpt2_cd          VARCHAR2(4),   -- ��{���R�[�h
       dpt3_cd          VARCHAR2(4),   -- �{���R�[�h
       dpt4_cd          VARCHAR2(4),   -- �G���A�R�[�h
       dpt5_cd          VARCHAR2(4)    -- �n��R�[�h
  );
  -- �Ј��f�[�^���i�[����e�[�u���^�̒�`
  TYPE people_data_tbl  IS TABLE OF people_data_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_filepath               VARCHAR2(255);        -- �A�g�pCSV�t�@�C���o�͐�
  gv_filename               VARCHAR2(255);        -- �A�g�pCSV�t�@�C����
  gv_jyugyoin_kbn           VARCHAR2(10);         -- �]�ƈ��敪�̃_�~�[�l
  gd_process_date           DATE;                 -- �Ɩ����t
  gd_select_start_date      DATE;                 -- �擾�J�n��
  gd_select_start_datetime  DATE;                 -- �擾�J�n��(���� 00:00:00)
  gd_select_end_date        DATE;                 -- �擾�I����
  gd_select_end_datetime    DATE;                 -- �擾�I����(���� 23:59:59)
  gf_file_hand              UTL_FILE.FILE_TYPE;   -- �t�@�C���E�n���h���̐錾
  gv_update_sdate           VARCHAR2(10);         -- ���̓p�����[�^�F�ŏI�X�V��(�J�n)
  gv_update_edate           VARCHAR2(10);         -- ���̓p�����[�^�F�ŏI�X�V��(�I��)
  gv_warn_flg               VARCHAR2(1);          -- �x���t���O
  gt_people_data_tbl        people_data_tbl;      -- �����z��̒�`
  gv_param_output_flg       VARCHAR2(1);          -- ���̓p�����[�^�o�̓t���O(�o�͑O:0�A�o�͌�:1)
  gd_sysdate                DATE;                 -- �V�X�e�����t
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  -- ���̓p�����[�^�̊J�n���Ȃ��ꍇ
  CURSOR get_people_data1_cur
  IS
    SELECT   SUBSTRB(a.ass_attribute5,1,4) AS ass_attribute5,                                                -- ���_�i����j�R�[�h
             SUBSTRB(a.ass_attribute3,1,4) AS ass_attribute3,                                                -- �Ζ��n�R�[�h
             SUBSTRB(p.attribute11,1,3) AS attribute11,                                                      -- �E�ʃR�[�h
             SUBSTRB(a.ass_attribute11,1,2) AS ass_attribute11,                                              -- �E�ʕ����R�[�h
             SUBSTRB(p.attribute12,1,20) AS attribute12,                                                     -- �E�ʖ�
             SUBSTRB(p.employee_number,1,5) AS employee_number,                                              -- �Ј��ԍ�
             SUBSTRB(p.last_name || ' ' || p.first_name,1,20) AS kana,                                       -- �]�ƈ������i�J�i�j
             SUBSTRB(p.per_information18 || '�@' || p.per_information19,1,20) AS kanji,                      -- �]�ƈ������i�����j
             SUBSTRB(p.sex,1,1) AS sex,                                                                      -- ���ʋ敪
             TO_CHAR(p.effective_start_date,'YYYYMMDD') AS start_date,                                       -- ���ДN����
             NVL2(s.actual_termination_date,TO_CHAR(s.actual_termination_date,'YYYYMMDD'),NULL) AS at_date,  -- �ސE�N����
             SUBSTRB(a.ass_attribute1,1,2) AS ass_attribute1,                                                -- �ٓ����R�R�[�h
             a.ass_attribute2 AS ass_attribute2,                                                             -- �K�p�J�n��
             SUBSTRB(p.attribute7,1,3) AS attribute7,                                                        -- ���i�R�[�h
             SUBSTRB(p.attribute8,1,20) AS attribute8,                                                       -- ���i��
             SUBSTRB(p.attribute19,1,2) AS attribute19,                                                      -- �E��R�[�h
             SUBSTRB(p.attribute20,1,20) AS attribute20,                                                     -- �E�햼
             SUBSTRB(p.attribute15,1,3) AS attribute15,                                                      -- �E���R�[�h
             SUBSTRB(p.attribute16,1,20) AS attribute16,                                                     -- �E����
             SUBSTRB(a.ass_attribute13,1,7) AS ass_attribute13,                                              -- ���F�敪
             SUBSTRB(a.ass_attribute15,1,7) AS ass_attribute15,                                              -- ��s�敪
             a.assignment_id AS assignment_id,                                                               -- �A�T�C�������gID
             a.ass_attribute18 AS ass_attribute18,                                                           -- �����A�g�p���t(���[)
             SUBSTRB(b.dpt2_cd,1,4) AS dpt2_cd,                                                              -- ��{���R�[�h
             SUBSTRB(b.dpt3_cd,1,4) AS dpt3_cd,                                                              -- �{���R�[�h
             SUBSTRB(b.dpt4_cd,1,4) AS dpt4_cd,                                                              -- �G���A�R�[�h
             SUBSTRB(b.dpt5_cd,1,4) AS dpt5_cd                                                               -- �n��R�[�h
    FROM     xxcmm_hierarchy_dept_all_v b,
             per_periods_of_service s,
             per_all_assignments_f a,
             per_all_people_f p,
             (SELECT   pp.person_id AS person_id,
                       MAX(pp.effective_start_date) as effective_start_date
              FROM     per_all_people_f pp
              WHERE    pp.current_emp_or_apl_flag = 'Y'
              GROUP BY pp.person_id) pp
    WHERE    pp.person_id = p.person_id
    AND      pp.effective_start_date = p.effective_start_date
    AND      (p.last_update_date <= gd_select_end_datetime AND a.last_update_date <= gd_select_end_datetime)
    AND      p.person_id = a.person_id
    AND      p.effective_start_date = a.effective_start_date
    AND      a.period_of_service_id = s.period_of_service_id
    AND      (NVL(p.attribute3,' ') > gv_jyugyoin_kbn OR NVL(p.attribute3,' ') < gv_jyugyoin_kbn)
    AND      ((a.ass_attribute18 IS NULL)
             OR
             (a.ass_attribute18 < TO_CHAR(p.last_update_date,'YYYYMMDD HH24:MI:SS'))
             OR
             (a.ass_attribute18 < TO_CHAR(a.last_update_date,'YYYYMMDD HH24:MI:SS')))
    AND      (s.actual_termination_date IS NULL OR s.actual_termination_date <= gd_select_end_date)
    AND      a.ass_attribute5 = b.cur_dpt_cd(+)
    ORDER BY p.employee_number
  ;
  --
  -- ���̓p�����[�^�̊J�n������ꍇ
  CURSOR get_people_data2_cur
  IS
    SELECT   SUBSTRB(a.ass_attribute5,1,4) AS ass_attribute5,                                                -- ���_�i����j�R�[�h
             SUBSTRB(a.ass_attribute3,1,4) AS ass_attribute3,                                                -- �Ζ��n�R�[�h
             SUBSTRB(p.attribute11,1,3) AS attribute11,                                                      -- �E�ʃR�[�h
             SUBSTRB(a.ass_attribute11,1,2) AS ass_attribute11,                                              -- �E�ʕ����R�[�h
             SUBSTRB(p.attribute12,1,20) AS attribute12,                                                     -- �E�ʖ�
             SUBSTRB(p.employee_number,1,5) AS employee_number,                                              -- �Ј��ԍ�
             SUBSTRB(p.last_name || ' ' || p.first_name,1,20) AS kana,                                       -- �]�ƈ������i�J�i�j
             SUBSTRB(p.per_information18 || '�@' || p.per_information19,1,20) AS kanji,                      -- �]�ƈ������i�����j
             SUBSTRB(p.sex,1,1) AS sex,                                                                      -- ���ʋ敪
             TO_CHAR(p.effective_start_date,'YYYYMMDD') AS start_date,                                       -- ���ДN����
             NVL2(s.actual_termination_date,TO_CHAR(s.actual_termination_date,'YYYYMMDD'),NULL) AS at_date,  -- �ސE�N����
             SUBSTRB(a.ass_attribute1,1,2) AS ass_attribute1,                                                -- �ٓ����R�R�[�h
             a.ass_attribute2 AS ass_attribute2,                                                             -- �K�p�J�n��
             SUBSTRB(p.attribute7,1,3) AS attribute7,                                                        -- ���i�R�[�h
             SUBSTRB(p.attribute8,1,20) AS attribute8,                                                       -- ���i��
             SUBSTRB(p.attribute19,1,2) AS attribute19,                                                      -- �E��R�[�h
             SUBSTRB(p.attribute20,1,20) AS attribute20,                                                     -- �E�햼
             SUBSTRB(p.attribute15,1,3) AS attribute15,                                                      -- �E���R�[�h
             SUBSTRB(p.attribute16,1,20) AS attribute16,                                                     -- �E����
             SUBSTRB(a.ass_attribute13,1,7) AS ass_attribute13,                                              -- ���F�敪
             SUBSTRB(a.ass_attribute15,1,7) AS ass_attribute15,                                              -- ��s�敪
             a.assignment_id AS assignment_id,                                                               -- �A�T�C�������gID
             a.ass_attribute18 AS ass_attribute18,                                                           -- �����A�g�p���t(���[)
             SUBSTRB(b.dpt2_cd,1,4) AS dpt2_cd,                                                              -- ��{���R�[�h
             SUBSTRB(b.dpt3_cd,1,4) AS dpt3_cd,                                                              -- �{���R�[�h
             SUBSTRB(b.dpt4_cd,1,4) AS dpt4_cd,                                                              -- �G���A�R�[�h
             SUBSTRB(b.dpt5_cd,1,4) AS dpt5_cd                                                               -- �n��R�[�h
    FROM     xxcmm_hierarchy_dept_all_v b,
             per_periods_of_service s,
             per_all_assignments_f a,
             per_all_people_f p,
             (SELECT   pp.person_id AS person_id,
                       MAX(pp.effective_start_date) as effective_start_date
              FROM     per_all_people_f pp
              WHERE    pp.current_emp_or_apl_flag = 'Y'
              GROUP BY pp.person_id) pp
    WHERE    pp.person_id = p.person_id
    AND      pp.effective_start_date = p.effective_start_date
    AND      (NVL(p.attribute3,' ') > gv_jyugyoin_kbn OR NVL(p.attribute3,' ') < gv_jyugyoin_kbn)
    AND      ((gd_select_start_datetime <= p.last_update_date AND p.last_update_date <= gd_select_end_datetime)
              OR (gd_select_start_datetime <= a.last_update_date AND a.last_update_date <= gd_select_end_datetime))
    AND      p.person_id = a.person_id
    AND      p.effective_start_date = a.effective_start_date
    AND      a.period_of_service_id = s.period_of_service_id
    AND      (s.actual_termination_date IS NULL OR s.actual_termination_date <= gd_select_end_date)
    AND      a.ass_attribute5 = b.cur_dpt_cd(+)
    ORDER BY p.employee_number
  ;
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
    -- ���̓p�����[�^�̊J�n���Ȃ��ꍇ
    CURSOR get_assignment1_cur IS
      SELECT   a.assignment_id
      FROM     per_periods_of_service s,
               per_all_assignments_f a,
               per_all_people_f p
      WHERE    (p.last_update_date <= gd_select_end_datetime AND a.last_update_date <= gd_select_end_datetime)
      AND      p.person_id = a.person_id
      AND      p.effective_start_date = a.effective_start_date
      AND      a.period_of_service_id = s.period_of_service_id
      AND      (NVL(p.attribute3,' ') > gv_jyugyoin_kbn OR NVL(p.attribute3,' ') < gv_jyugyoin_kbn)
      AND      ((a.ass_attribute18 IS NULL)
               OR
               (a.ass_attribute18 < TO_CHAR(p.last_update_date,'YYYYMMDD HH24:MI:SS'))
               OR
               (a.ass_attribute18 < TO_CHAR(a.last_update_date,'YYYYMMDD HH24:MI:SS')))
      AND      (s.actual_termination_date IS NULL OR s.actual_termination_date <= gd_select_end_date)
      FOR UPDATE NOWAIT;
    --
    -- ���̓p�����[�^�̊J�n������ꍇ
    CURSOR get_assignment2_cur IS
      SELECT   a.assignment_id
      FROM     per_periods_of_service s,
               per_all_assignments_f a,
               per_all_people_f p
      WHERE    (NVL(p.attribute3,' ') > gv_jyugyoin_kbn OR NVL(p.attribute3,' ') < gv_jyugyoin_kbn)
      AND      ((gd_select_start_datetime <= p.last_update_date AND p.last_update_date <= gd_select_end_datetime)
                OR (gd_select_start_datetime <= a.last_update_date AND a.last_update_date <= gd_select_end_datetime))
      AND      p.person_id = a.person_id
      AND      p.effective_start_date = a.effective_start_date
      AND      a.period_of_service_id = s.period_of_service_id
      AND      (s.actual_termination_date IS NULL OR s.actual_termination_date <= gd_select_end_date)
      FOR UPDATE NOWAIT;
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
    -- =========================================================
    --  �擾�J�n���A�擾�I�����̎擾
    -- =========================================================
    -- �Ɩ����t�̎擾
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00018           -- �Ɩ��������t�擾�G���[
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- �擾�J�n���̎擾
    IF (gv_update_sdate IS NOT NULL) THEN
      gd_select_start_date := TO_DATE(gv_update_sdate,'YYYY/MM/DD');
      gd_select_start_datetime := TO_DATE(gv_update_sdate || ' 00:00:00','YYYY/MM/DD HH24:MI:SS');
    END IF;
    -- �擾�I�����̎擾
    IF (gv_update_edate IS NULL) THEN
      -- �Ɩ����t���Z�b�g
      gd_select_end_date := gd_process_date;
    ELSE
      -- �ŏI�X�V��(�I��)���Z�b�g
      gd_select_end_date := TO_DATE(gv_update_edate,'YYYY/MM/DD');
    END IF;
    gd_select_end_datetime := TO_DATE(TO_CHAR(gd_select_end_date,'YYYY/MM/DD') || ' 23:59:59','YYYY/MM/DD HH24:MI:SS');
    -- =========================================================
    --  �Œ�o��(���̓p�����[�^��)
    -- =========================================================
    -- ���̓p�����[�^
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                    ,iv_name         => cv_msg_00038           -- ���̓p�����[�^�o�̓��b�Z�[�W
                    ,iv_token_name1  => cv_tkn_param           -- �g�[�N��(PARAM)
                    ,iv_token_value1 => cv_tkn_param3          -- �p�����[�^��(���̓p�����[�^)
                    ,iv_token_name2  => cv_tkn_value           -- �g�[�N��(VALUE)
                    ,iv_token_value2 => gv_update_sdate || '.' || gv_update_edate
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
                    ,iv_token_value1 => cv_tkn_param1          -- �p�����[�^��(�ŏI�X�V��(�J�n))
                    ,iv_token_name2  => cv_tkn_value           -- �g�[�N��(VALUE)
                    ,iv_token_value2 => gv_update_sdate
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    -- �擾�I����
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                    ,iv_name         => cv_msg_00038           -- ���̓p�����[�^�o�̓��b�Z�[�W
                    ,iv_token_name1  => cv_tkn_param           -- �g�[�N��(PARAM)
                    ,iv_token_value1 => cv_tkn_param2          -- �p�����[�^��(�ŏI�X�V��(�I��))
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
    IF (gv_update_sdate IS NOT NULL) THEN
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
--
    -- =============================================================================
    --  �v���t�@�C���̎擾(CSV�t�@�C���o�͐�ACSV�t�@�C�����A�]�ƈ��敪�̃_�~�[�l)
    -- =============================================================================
    gv_filepath := fnd_profile.value(cv_filepath);
    IF (gv_filepath IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00002           -- �v���t�@�C���擾�G���[
                      ,iv_token_name1  => cv_tkn_profile         -- �g�[�N��(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_filepath_nm     -- �v���t�@�C����(CSV�t�@�C���o�͐�)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    gv_filename := fnd_profile.value(cv_filename);
    IF (gv_filename IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00002           -- �v���t�@�C���擾�G���[
                      ,iv_token_name1  => cv_tkn_profile         -- �g�[�N��(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_filename_nm     -- �v���t�@�C����(CSV�t�@�C����)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    gv_jyugyoin_kbn := fnd_profile.value(cv_jyugyoin_kbn);
    IF (gv_jyugyoin_kbn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00002           -- �v���t�@�C���擾�G���[
                      ,iv_token_name1  => cv_tkn_profile         -- �g�[�N��(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_jyugoin_kbn_nm  -- �v���t�@�C����(�]�ƈ��敪�̃_�~�[�l)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- =========================================================
    --  �Œ�o��(I/F�t�@�C������)
    -- =========================================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp           -- 'XXCCP'
                    ,iv_name         => cv_msg_05102             -- �t�@�C�����o�̓��b�Z�[�W
                    ,iv_token_name1  => cv_tkn_filename          -- �g�[�N��(FILE_NAME)
                    ,iv_token_value1 => gv_filename              -- �t�@�C����
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- ��s�}��(I/F�t�@�C�����̉�)
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
                         iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                        ,iv_name         => cv_msg_00003         -- �t�@�C���p�X�s���G���[
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- =========================================================
    --  �A�T�C�������g�}�X�^�̍s���b�N
    -- =========================================================
    BEGIN
      IF (gv_update_sdate IS NULL) THEN
        OPEN get_assignment1_cur;
        CLOSE get_assignment1_cur;
      ELSE
        OPEN get_assignment2_cur;
        CLOSE get_assignment2_cur;
      END IF;
    EXCEPTION
      -- �e�[�u�����b�N�G���[
      WHEN lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                        ,iv_name         => cv_msg_00008         -- ���b�N�擾NG���b�Z�[�W
                        ,iv_token_name1  => cv_tkn_table         -- �g�[�N��(NG_TABLE)
                        ,iv_token_value1 => cv_tkn_table_nm      -- �e�[�u����(�A�T�C�������g�}�X�^)
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
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
    IF (gv_update_sdate IS NULL) THEN
      OPEN get_people_data1_cur;
      <<people_data1_loop>>
      LOOP
        FETCH get_people_data1_cur BULK COLLECT INTO gt_people_data_tbl;
        EXIT WHEN get_people_data1_cur%NOTFOUND;
      END LOOP people_data1_loop;
      CLOSE get_people_data1_cur;
    ELSE
      OPEN get_people_data2_cur;
      <<people_data2_loop>>
      LOOP
        FETCH get_people_data2_cur BULK COLLECT INTO gt_people_data_tbl;
        EXIT WHEN get_people_data2_cur%NOTFOUND;
      END LOOP people_data2_loop;
      CLOSE get_people_data2_cur;
    END IF;
--
    -- �Ώی������Z�b�g
    gn_target_cnt := gt_people_data_tbl.COUNT;
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
   * Description      : CSV�t�@�C���o�̓v���V�[�W��(A-5)
   ***********************************************************************************/
  PROCEDURE output_csv(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv';            -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    ln_loop_cnt         NUMBER;                   -- ���[�v�J�E���^
    lv_csv_text         VARCHAR2(32000);          -- �o�͂P�s��������ϐ�
    lv_update_kbn       VARCHAR2(1);              -- �X�V�敪
    lv_employee_number  VARCHAR2(5);              -- �]�ƈ��ԍ��d���`�F�b�N�p
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
    --========================================
    -- CSV�w�b�_�o��(A-3)
    --========================================
    lv_csv_text := cv_enclosed || cv_nm1 || cv_enclosed || cv_delimiter                               -- �f�[�^��
      || cv_enclosed || cv_nm2 || cv_enclosed || cv_delimiter                                         -- �t�@�C����
      || cv_enclosed || cv_nm3 || cv_enclosed || cv_delimiter                                         -- �X�V�敪
      || cv_enclosed || cv_nm4 || cv_enclosed || cv_delimiter                                         -- ���_�i����j�R�[�h
      || cv_enclosed || cv_nm5 || cv_enclosed || cv_delimiter                                         -- �Ζ��n�R�[�h
      || cv_enclosed || cv_nm6 || cv_enclosed || cv_delimiter                                         -- ��{���R�[�h
      || cv_enclosed || cv_nm7 || cv_enclosed || cv_delimiter                                         -- �{���R�[�h
      || cv_enclosed || cv_nm8 || cv_enclosed || cv_delimiter                                         -- �G���A�R�[�h
      || cv_enclosed || cv_nm9 || cv_enclosed || cv_delimiter                                         -- �n��R�[�h
      || cv_enclosed || cv_nm10 || cv_enclosed || cv_delimiter                                        -- �E�ʃR�[�h
      || cv_enclosed || cv_nm11 || cv_enclosed || cv_delimiter                                        -- �E�ʕ����R�[�h
      || cv_enclosed || cv_nm12 || cv_enclosed || cv_delimiter                                        -- �E�ʖ�
      || cv_enclosed || cv_nm13 || cv_enclosed || cv_delimiter                                        -- �Ј��ԍ�
      || cv_enclosed || cv_nm14 || cv_enclosed || cv_delimiter                                        -- �]�ƈ������i�J�i�j
      || cv_enclosed || cv_nm15 || cv_enclosed || cv_delimiter                                        -- �]�ƈ������i�����j
      || cv_enclosed || cv_nm16 || cv_enclosed || cv_delimiter                                        -- ���N����
      || cv_enclosed || cv_nm17 || cv_enclosed || cv_delimiter                                        -- ���ʋ敪
      || cv_enclosed || cv_nm18 || cv_enclosed || cv_delimiter                                        -- ���ДN����
      || cv_enclosed || cv_nm19 || cv_enclosed || cv_delimiter                                        -- �ސE�N����
      || cv_enclosed || cv_nm20 || cv_enclosed || cv_delimiter                                        -- �ٓ����R�R�[�h
      || cv_enclosed || cv_nm21 || cv_enclosed || cv_delimiter                                        -- �K�p�J�n��
      || cv_enclosed || cv_nm22 || cv_enclosed || cv_delimiter                                        -- ���i�R�[�h
      || cv_enclosed || cv_nm23 || cv_enclosed || cv_delimiter                                        -- ���i��
      || cv_enclosed || cv_nm24 || cv_enclosed || cv_delimiter                                        -- �E��R�[�h
      || cv_enclosed || cv_nm25 || cv_enclosed || cv_delimiter                                        -- �E�햼
      || cv_enclosed || cv_nm26 || cv_enclosed || cv_delimiter                                        -- �E���R�[�h
      || cv_enclosed || cv_nm27 || cv_enclosed || cv_delimiter                                        -- �E����
      || cv_enclosed || cv_nm28 || cv_enclosed || cv_delimiter                                        -- ���F�敪
      || cv_enclosed || cv_nm29 || cv_enclosed || cv_delimiter                                        -- ��s�敪
      || cv_enclosed || cv_nm30 || cv_enclosed || cv_delimiter                                        -- �쐬�N����
      || cv_enclosed || cv_nm31 || cv_enclosed                                                        -- �ŏI�X�V��
    ;
    BEGIN
      -- �t�@�C����������
      UTL_FILE.PUT_LINE(gf_file_hand,lv_csv_text);
    EXCEPTION
      -- �t�@�C���A�N�Z�X�����G���[
      WHEN UTL_FILE.INVALID_OPERATION THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                        ,iv_name         => cv_msg_00007             -- �t�@�C���A�N�Z�X�����G���[
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      --
      -- CSV�f�[�^�o�̓G���[
      WHEN UTL_FILE.WRITE_ERROR THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                        ,iv_name         => cv_msg_00009             -- CSV�f�[�^�o�̓G���[
                        ,iv_token_name1  => cv_tkn_word              -- �g�[�N��(NG_WORD)
                        ,iv_token_value1 => cv_tkn_word2             -- CSV�w�b�_
                        ,iv_token_name2  => cv_tkn_data              -- �g�[�N��(NG_DATA)
                        ,iv_token_value2 => NULL                     -- NULL
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    --
    lv_employee_number := ' ';
    <<out_loop>>
    FOR ln_loop_cnt IN 1..gn_target_cnt LOOP
      --========================================
      -- ���_�R�[�h(�V)�̓��̓`�F�b�N(A-4-1)
      --========================================
      IF (gt_people_data_tbl(ln_loop_cnt).ass_attribute5 IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm                                 -- 'XXCMM'
                        ,iv_name         => cv_msg_00205                                   -- ���_�R�[�h(�V)�擾�G���[
                        ,iv_token_name1  => cv_tkn_word                                    -- �g�[�N��(NG_WORD)
                        ,iv_token_value1 => cv_tkn_word1                                   -- NG_WORD
                        ,iv_token_name2  => cv_tkn_data                                    -- �g�[�N��(NG_DATA)
                        ,iv_token_value2 => gt_people_data_tbl(ln_loop_cnt).employee_number    -- NG_WORD��DATA
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --========================================
      -- AFF����擾�`�F�b�N(A-4-2)
      --========================================
      IF (gt_people_data_tbl(ln_loop_cnt).dpt2_cd IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm                                 -- 'XXCMM'
                        ,iv_name         => cv_msg_00501                                   -- ���_�R�[�h(�V)�擾�G���[
                        ,iv_token_name1  => cv_tkn_kyoten                                  -- �g�[�N��(NG_KYOTEN)
                        ,iv_token_value1 => gt_people_data_tbl(ln_loop_cnt).ass_attribute5 -- NG_KYOTEN
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --========================================
      -- �]�ƈ��ԍ��d���`�F�b�N(A-4-3)
      -- (�]�ƈ��ԍ����d�����Ă���ꍇ�A�x�����b�Z�[�W��\��)
      --========================================
      IF (lv_employee_number = gt_people_data_tbl(ln_loop_cnt).employee_number) THEN
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
                         iv_application  => cv_msg_kbn_cmm                                 -- 'XXCMM'
                        ,iv_name         => cv_msg_00209                                   -- �]�ƈ��ԍ��d�����b�Z�[�W
                        ,iv_token_name1  => cv_tkn_word                                    -- �g�[�N��(NG_WORD)
                        ,iv_token_value1 => cv_tkn_word1                                   -- NG_WORD
                        ,iv_token_name2  => cv_tkn_data                                    -- �g�[�N��(NG_DATA)
                        ,iv_token_value2 => gt_people_data_tbl(ln_loop_cnt).employee_number    -- NG_WORD��DATA
                                              || cv_tkn_word3
                                              || gt_people_data_tbl(ln_loop_cnt).kanji
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
      -- CSV�t�@�C���o��(A-5)
      --========================================
      -- �X�V�敪�̎擾
      IF (gt_people_data_tbl(ln_loop_cnt).at_date IS NOT NULL) THEN
        lv_update_kbn := cv_value3_delete;
      ELSIF ((gt_people_data_tbl(ln_loop_cnt).ass_attribute18 IS NULL)
             OR (TO_CHAR(gd_select_end_date,'YYYYMMDD') < gt_people_data_tbl(ln_loop_cnt).start_date))
      THEN
        lv_update_kbn := cv_value3_add;
      ELSE
        lv_update_kbn := cv_value3_update;
      END IF;
      lv_csv_text := cv_enclosed || cv_value1 || cv_enclosed || cv_delimiter                              -- �f�[�^��
        || cv_enclosed || cv_value2 || cv_enclosed || cv_delimiter                                        -- �t�@�C����
        || lv_update_kbn || cv_delimiter                                                                  -- �X�V�敪
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).ass_attribute5 || cv_enclosed || cv_delimiter   -- ���_�i����j�R�[�h
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).ass_attribute3 || cv_enclosed || cv_delimiter   -- �Ζ��n�R�[�h
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).dpt2_cd || cv_enclosed || cv_delimiter          -- ��{���R�[�h
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).dpt3_cd || cv_enclosed || cv_delimiter          -- �{���R�[�h
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).dpt4_cd || cv_enclosed || cv_delimiter          -- �G���A�R�[�h
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).dpt5_cd || cv_enclosed || cv_delimiter          -- �n��R�[�h
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).attribute11 || cv_enclosed || cv_delimiter      -- �E�ʃR�[�h
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).ass_attribute11 || cv_enclosed || cv_delimiter  -- �E�ʕ����R�[�h
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).attribute12 || cv_enclosed || cv_delimiter      -- �E�ʖ�
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).employee_number || cv_enclosed || cv_delimiter  -- �Ј��ԍ�
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).kana || cv_enclosed || cv_delimiter             -- �]�ƈ������i�J�i�j
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).kanji || cv_enclosed || cv_delimiter            -- �]�ƈ������i�����j
        || NULL || cv_delimiter                                                                           -- ���N����
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).sex || cv_enclosed || cv_delimiter              -- ���ʋ敪
        || gt_people_data_tbl(ln_loop_cnt).start_date || cv_delimiter                                     -- ���ДN����
        || gt_people_data_tbl(ln_loop_cnt).at_date || cv_delimiter                                        -- �ސE�N����
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).ass_attribute1 || cv_enclosed || cv_delimiter   -- �ٓ����R�R�[�h
        || gt_people_data_tbl(ln_loop_cnt).ass_attribute2 || cv_delimiter                                 -- �K�p�J�n��
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).attribute7 || cv_enclosed || cv_delimiter       -- ���i�R�[�h
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).attribute8 || cv_enclosed || cv_delimiter       -- ���i��
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).attribute19 || cv_enclosed || cv_delimiter      -- �E��R�[�h
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).attribute20 || cv_enclosed || cv_delimiter      -- �E�햼
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).attribute15 || cv_enclosed || cv_delimiter      -- �E���R�[�h
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).attribute16 || cv_enclosed || cv_delimiter      -- �E����
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).ass_attribute13 || cv_enclosed || cv_delimiter  -- ���F�敪
        || cv_enclosed || gt_people_data_tbl(ln_loop_cnt).ass_attribute15 || cv_enclosed || cv_delimiter  -- ��s�敪
        || NULL || cv_delimiter                                                                           -- �쐬�N����
        || NULL                                                                                           -- �ŏI�X�V��
      ;
      BEGIN
        -- �t�@�C����������
        UTL_FILE.PUT_LINE(gf_file_hand,lv_csv_text);
      EXCEPTION
        -- �t�@�C���A�N�Z�X�����G���[
        WHEN UTL_FILE.INVALID_OPERATION THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm                               -- 'XXCMM'
                          ,iv_name         => cv_msg_00007                                 -- �t�@�C���A�N�Z�X�����G���[
                         );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        --
        -- CSV�f�[�^�o�̓G���[
        WHEN UTL_FILE.WRITE_ERROR THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm                               -- 'XXCMM'
                          ,iv_name         => cv_msg_00009                                 -- CSV�f�[�^�o�̓G���[
                          ,iv_token_name1  => cv_tkn_word                                  -- �g�[�N��(NG_WORD)
                          ,iv_token_value1 => cv_tkn_word1                                 -- NG_WORD
                          ,iv_token_name2  => cv_tkn_data                                  -- �g�[�N��(NG_DATA)
                          ,iv_token_value2 => gt_people_data_tbl(ln_loop_cnt).employee_number  -- NG_WORD��DATA
                         );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
      --===============================================
      -- �����A�g�p���t�X�V(�A�T�C�������g�}�X�^)(A-6)
      --===============================================
      BEGIN
        UPDATE   per_all_assignments_f
        SET      ass_attribute18 = TO_CHAR(SYSDATE,'YYYYMMDD HH24:MI:SS')
        WHERE    assignment_id = gt_people_data_tbl(ln_loop_cnt).assignment_id
        AND      effective_start_date = TO_DATE(gt_people_data_tbl(ln_loop_cnt).start_date,'YYYYMMDD');
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm                               -- 'XXCMM'
                          ,iv_name         => cv_msg_00029                                 -- �A�T�C�������g�}�X�^�X�V�G���[
                          ,iv_token_name1  => cv_tkn_word                                  -- �g�[�N��(NG_WORD)
                          ,iv_token_value1 => cv_tkn_word1                                 -- NG_WORD
                          ,iv_token_name2  => cv_tkn_data                                  -- �g�[�N��(NG_DATA)
                          ,iv_token_value2 => gt_people_data_tbl(ln_loop_cnt).employee_number  -- NG_WORD��DATA
                         );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
      -- ���������̃J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
      lv_employee_number := gt_people_data_tbl(ln_loop_cnt).employee_number;
    END LOOP out_loop;
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
    gn_error_cnt  := 0;
    gv_warn_flg   := '0';
    gv_param_output_flg := '0';
    --
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    --
    -- =====================================================
    --  ���������v���V�[�W��(A-1)
    -- =====================================================
    init(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  �Ј��f�[�^�擾�v���V�[�W��(A-2)
    -- =====================================================
    get_people_data(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  CSV�t�@�C���o�̓v���V�[�W��(A-5)
    -- =====================================================
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
    iv_date_from  IN  VARCHAR2,      --   1.�ŏI�X�V��(�J�n)
    iv_date_to    IN  VARCHAR2       --   2.�ŏI�X�V��(�I��)
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
    -- ���̓p�����[�^�̎擾
    -- ===============================================
    gv_update_sdate := iv_date_from;
    gv_update_edate := iv_date_to;
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
      IF (gv_param_output_flg = '1') THEN
        -- ��s�}��(���O�̓��̓p�����[�^�̉�)
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
      gn_error_cnt  := 1;
    ELSE
      IF (gv_warn_flg = '1') THEN
        -- �x���̏ꍇ�A���^�[���E�R�[�h�Ɍx�����Z�b�g����
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
    -- ��s�}��(�I�����b�Z�[�W�̏�)
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
END XXCMM002A04C;
/
