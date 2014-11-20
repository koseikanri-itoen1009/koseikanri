CREATE OR REPLACE PACKAGE BODY XXCOP001A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP001A01C(body)
 * Description      : �A�b�v���[�h�t�@�C������̓o�^�i��v��j
 * MD.050           : �A�b�v���[�h�t�@�C������̓o�^�i��v��j MD050_COP_001_A01
 * Version          : ver1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  output_disp            ���b�Z�[�W�o��
 *  check_validate_item    ���ڑ����`�F�b�N
 *  init                   ��������                            (A-1)
 *  get_file_info          �֘A�f�[�^�擾                       (A-2)
 *  get_upload_data        �t�@�C���A�b�v���[�hI/F�e�[�u���f�[�^���o(A-3)
 *  chk_upload_data        �Ó����`�F�b�N                       (A-4)
 *  insert_data            �f�[�^�o�^                           (A-6)
 *  delete_data            �t�@�C���A�b�v���[�hI/F�e�[�u���f�[�^�폜(A-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/21    1.0  SCS.Uchida       �V�K�쐬
 *  2009/04/03    1.1  SCS.Goto         T1_0237�AT1_0270�Ή�
 *
 *****************************************************************************************/
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  gv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  gv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  gv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  gn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  gd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  gn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  gd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  gn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  gn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  gn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  gn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  gd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  --�V�X�e���ݒ�
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCOP001A01C'; -- �p�b�P�[�W��
  gv_debug_mode                VARCHAR2(10)  := NULL;           -- �f�o�b�O���[�h�FON/OFF
  --�N�����[�U�[
  gn_user_id          CONSTANT NUMBER        := fnd_global.user_id;
  --���b�Z�[�W�ݒ�
  gv_xxcop            CONSTANT VARCHAR2(100) := 'XXCOP';              -- �A�v���P�[�V�����Z�k��
  gv_m_e_get_who      CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00001';   -- WHO�J�����擾���s
  gv_m_e_get_pro      CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00002';   -- �v���t�@�C���l�擾���s
  gv_m_e_no_data      CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00003';   -- �Ώۃf�[�^�Ȃ�
  gv_m_e_Param        CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00005';   -- �p�����[�^�G���[���b�Z�[�W
  gv_m_e_lock         CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00007';   -- �e�[�u�����b�N�G���[���b�Z�[�W
  gv_m_e_not_exist    CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00017';   -- �}�X�^���o�^�G���[���b�Z�[�W
  gv_m_e_chk_err      CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00018';   -- �s���`�F�b�N�G���[���b�Z�[�W
  gv_m_e_set_err      CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00019';   -- �֎~���ڐݒ�G���[
  gv_m_e_nchk         CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00020';   -- NUMBER�^�`�F�b�N�G���[
  gv_m_e_dchk         CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00021';   -- DATE�^�`�F�b�N�G���[
  gv_m_e_schk         CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00022';   -- �T�C�Y�`�F�b�N�G���[
  gv_m_e_input        CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00023';   -- �K�{���̓G���[���b�Z�[�W
  gv_m_e_fchk         CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00024';   -- �t�H�[�}�b�g�`�F�b�N�G���[���b�Z�[�W
  gv_m_e_insert_err   CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00027';   -- �o�^�����G���[���b�Z�[�W
  gv_m_e_get_f_info   CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00032';   -- �A�b�v���[�hIF���擾�G���[���b�Z�[�W
  gv_m_n_fname        CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00033';   -- �t�@�C�����o�̓��b�Z�[�W
  gv_m_e_fopen        CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00034';   -- �t�@�C���I�[�v���������s
  gv_m_e_public       CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00035';   -- �W��API/Oracle�G���[���b�Z�[�W
  gv_m_n_up_f_info    CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00036';   -- �A�b�v���[�h�t�@�C���o�̓��b�Z�[�W
  gv_m_e_1rec_chk     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00040';   -- ��Ӑ��`�F�b�N�G���[���b�Z�[�W
  gv_m_e_user_chk     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10006';   -- �N�����[�U�[�`�F�b�N�G���[���b�Z�[�W
  gv_m_e_conc_call    CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10012';   -- �R���J�����g���s�G���[
  gv_m_e_set_err_t    CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10030';   -- ��v�敪�ޕs���G���[���b�Z�[�W
  gv_m_n_skip_rec     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10033';   -- ��v��m����ȑO�f�[�^�X�L�b�v���b�Z�[�W
  gv_m_e_unmatch      CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10034';   -- ��v�於���o�^�G���[
  gv_m_e_calendar_err CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10037';   -- �ғ����`�F�b�N�G���[
  --�g�[�N���ݒ�
  gv_t_prof_name      CONSTANT VARCHAR2(100) := 'PROF_NAME';
  gv_t_parameter      CONSTANT VARCHAR2(100) := 'PARAMETER';
  gv_t_value          CONSTANT VARCHAR2(100) := 'VALUE';
  gv_t_value1         CONSTANT VARCHAR2(100) := 'VALUE1';
  gv_t_table          CONSTANT VARCHAR2(100) := 'TABLE';
  gv_t_column         CONSTANT VARCHAR2(100) := 'COLUMN';
  gv_t_row_num        CONSTANT VARCHAR2(100) := 'ROW';
  gv_t_file           CONSTANT VARCHAR2(100) := 'FILE';
  gv_t_item           CONSTANT VARCHAR2(100) := 'ITEM';
  gv_t_fileid         CONSTANT VARCHAR2(100) := 'FILEID';
  gv_t_format         CONSTANT VARCHAR2(100) := 'FORMAT';
  gv_t_file_name      CONSTANT VARCHAR2(100) := 'FILE_NAME';
  gv_t_file_id        CONSTANT VARCHAR2(100) := 'FILE_ID';
  gv_t_format_ptn     CONSTANT VARCHAR2(100) := 'FORMAT_PTN';
  gv_t_upload_obj     CONSTANT VARCHAR2(100) := 'UPLOAD_OBJECT';
  gv_t_data           CONSTANT VARCHAR2(100) := 'DATA';
  gv_t_schedule_name  CONSTANT VARCHAR2(100) := 'SCHEDULE_NAME';
  gv_t_org_code       CONSTANT VARCHAR2(100) := 'ORG_CODE';
  gv_t_date           CONSTANT VARCHAR2(100) := 'DATE';
  gv_t_date1          CONSTANT VARCHAR2(100) := 'DATE1';
  gv_t_date2          CONSTANT VARCHAR2(100) := 'DATE2';
  gv_t_syori          CONSTANT VARCHAR2(100) := 'SYORI';
  gv_msg_comma        CONSTANT VARCHAR2(100) := ',';                  -- ���ڋ�؂�
  --�e�[�u����
  gv_table_name_item  CONSTANT VARCHAR2(100) := 'Disc�i�ڃ}�X�^';
  gv_table_name_org   CONSTANT VARCHAR2(100) := '�g�D�p�����[�^';
  gv_table_name_ift   CONSTANT VARCHAR2(100) := '��v��IF�\';
--20090403_Ver1.1_T1_0270_SCS.Goto_ADD_START
  gv_table_name_opm   CONSTANT VARCHAR2(100) := 'OPM�i�ڃ}�X�^';
--20090403_Ver1.1_T1_0270_SCS.Goto_ADD_END
  --�v���t�@�C����
  gv_p_base_date      CONSTANT VARCHAR2(100) := 'XXCOP1_SCHEDULE_BASELINE' ;  -- �m��������
  --�t�H�[�}�b�g�p�^�[��
  gv_format_mds_o     CONSTANT VARCHAR2(100) := '201';                -- ��v��i�o�ח\��MDS�j
  gv_format_mps_o     CONSTANT VARCHAR2(100) := '202';                -- ��v��i�H��o�׌v��MPS�j
  gv_format_mps_i     CONSTANT VARCHAR2(100) := '203';                -- ��v��i�w���v��MPS�j
  --���b�Z�[�W�o��
  gv_blank            CONSTANT VARCHAR2(5)   := 'BLANK';              -- �󔒍s
  --�t�@�C���A�b�v���[�hI/F�e�[�u��
  gv_delim            CONSTANT VARCHAR2(1)   := ',';                  -- �f���~�^����
  gn_column_num       CONSTANT NUMBER        := 10;                   -- ���ڐ�
  gn_header_row_num   CONSTANT NUMBER        := 1;                    -- �w�b�_�[�s��
  --���ڂ̓��{�ꖼ��
  gv_column_name_01   CONSTANT VARCHAR2(100) := 'MDS/MPS��';
  gv_column_name_02   CONSTANT VARCHAR2(100) := 'MDS/MPS�E�v';
  gv_column_name_03   CONSTANT VARCHAR2(100) := '�g�D�R�[�h';
  gv_column_name_04   CONSTANT VARCHAR2(100) := '��v�敪��';
  gv_column_name_05   CONSTANT VARCHAR2(100) := '�i�ڃR�[�h';
  gv_column_name_06   CONSTANT VARCHAR2(100) := '�v����t';
  gv_column_name_07   CONSTANT VARCHAR2(100) := '�v�搔��';
  gv_column_name_08   CONSTANT VARCHAR2(100) := '�o�׌��q�ɃR�[�h';
  gv_column_name_09   CONSTANT VARCHAR2(100) := '�o�ד�';
  gv_column_name_10   CONSTANT VARCHAR2(100) := '�v�揤�i�t���O';
  --���ڂ̃T�C�Y
  gv_column_len_01    CONSTANT NUMBER := 10;                          -- MDS/MPS��
  gv_column_len_02    CONSTANT NUMBER := 50;                          -- MDS/MPS�E�v
  gv_column_len_03    CONSTANT NUMBER := 3;                           -- �g�D�R�[�h
  gv_column_len_04    CONSTANT NUMBER := 1;                           -- ��v�敪��
  gv_column_len_05    CONSTANT NUMBER := 7;                           -- �i�ڃR�[�h
  gv_column_len_07    CONSTANT NUMBER := 8;                           -- �v�搔��
  gv_column_len_08    CONSTANT NUMBER := 3;                           -- �o�׌��q�ɃR�[�h
  gv_column_len_10    CONSTANT NUMBER := 1;                           -- �v�揤�i�t���O
  --�K�{����
  gv_must_item        CONSTANT VARCHAR2(4) := 'MUST';                 -- �K�{����
  gv_null_item        CONSTANT VARCHAR2(4) := 'NULL';                 -- NULL����
  gv_any_item         CONSTANT VARCHAR2(4) := 'ANY';                  -- �C�Ӎ���
  --���t�^�t�H�[�}�b�g
  gv_ymd_format       CONSTANT VARCHAR2(8)   := 'YYYYMMDD';           -- �N����
  gv_ymd_out_format   CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';         -- �N�����i�o�͗p�j
  --��v�惌�R�[�h�^
  TYPE xm_schedule_if_rtype IS RECORD (
--20090403_Ver1.1_T1_0237_SCS.Goto_MOD_START
--    schedule_designator     xxcop.xxcop_mrp_schedule_interface.schedule_designator%TYPE
--  , schedule_description    xxcop.xxcop_mrp_schedule_interface.schedule_description%TYPE
--  , organization_code       xxcop.xxcop_mrp_schedule_interface.organization_code%TYPE
--  , schedule_type           xxcop.xxcop_mrp_schedule_interface.schedule_type%TYPE
--  , item_code               xxcop.xxcop_mrp_schedule_interface.item_code%TYPE
--  , schedule_date           xxcop.xxcop_mrp_schedule_interface.schedule_date%TYPE
--  , schedule_quantity       xxcop.xxcop_mrp_schedule_interface.schedule_quantity%TYPE
--  , deliver_from            xxcop.xxcop_mrp_schedule_interface.deliver_from%TYPE
--  , shipment_date           xxcop.xxcop_mrp_schedule_interface.shipment_date%TYPE
--  , schedule_prod_flg       xxcop.xxcop_mrp_schedule_interface.schedule_prod_flg%TYPE
    schedule_designator     xxcop_mrp_schedule_interface.schedule_designator%TYPE
  , schedule_description    xxcop_mrp_schedule_interface.schedule_description%TYPE
  , organization_code       xxcop_mrp_schedule_interface.organization_code%TYPE
  , schedule_type           xxcop_mrp_schedule_interface.schedule_type%TYPE
  , item_code               xxcop_mrp_schedule_interface.item_code%TYPE
  , schedule_date           xxcop_mrp_schedule_interface.schedule_date%TYPE
  , schedule_quantity       xxcop_mrp_schedule_interface.schedule_quantity%TYPE
  , deliver_from            xxcop_mrp_schedule_interface.deliver_from%TYPE
  , shipment_date           xxcop_mrp_schedule_interface.shipment_date%TYPE
  , schedule_prod_flg       xxcop_mrp_schedule_interface.schedule_prod_flg%TYPE
  , num_of_cases            NUMBER
--20090403_Ver1.1_T1_0237_SCS.Goto_MOD_END
  );
  --��v��R���N�V�����^
  TYPE xm_schedule_if_ttype IS TABLE OF xm_schedule_if_rtype
    INDEX BY BINARY_INTEGER;
--
  /**********************************************************************************
   * Procedure Name   : output_disp
   * Description      : ���b�Z�[�W�o��
   ***********************************************************************************/
  PROCEDURE output_disp(
    iv_errmsg     IN OUT VARCHAR2,     -- 1.���|�[�g�o�̓��b�Z�[�W
    iv_errbuf     IN OUT VARCHAR2      -- 2.���O�o�̓��b�Z�[�W
  )
  IS
  BEGIN
      --���|�[�g�o��
      IF ( iv_errmsg IS NOT NULL ) THEN
        IF ( iv_errmsg = gv_blank ) THEN
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff => NULL
          );
        ELSE
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff => iv_errmsg
          );
        END IF;
      END IF;
      --���O�o��
      IF ( iv_errbuf IS NOT NULL ) THEN
        IF ( iv_errbuf = gv_blank ) THEN
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff => NULL
          );
        ELSE
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff => iv_errbuf
          );
        END IF;
      END IF;
      --�o�̓��b�Z�[�W�̃N���A
      iv_errmsg := NULL;
      iv_errbuf := NULL;
  END output_disp;
--
--
  /**********************************************************************************
   * Procedure Name   : check_validate_item
   * Description      : ���ڑ����`�F�b�N
   ***********************************************************************************/
  PROCEDURE check_validate_item(
    iv_item_name  IN  VARCHAR2,     -- 1.���ږ��i���{��j
    iv_item_value IN  VARCHAR2,     -- 2.���ڒl
    iv_null       IN  VARCHAR2,     -- 3.�K�{�`�F�b�N
    iv_number     IN  VARCHAR2,     -- 4.NUMBER�^�`�F�b�N
    iv_date       IN  VARCHAR2,     -- 5.DATE�^�`�F�b�N
    in_item_size  IN  NUMBER,       -- 6.���ڃT�C�Y�iBYTE�j
    in_row_num    IN  NUMBER,       -- 7.�s
    iv_file_data  IN  VARCHAR2,     -- 8.�擾���R�[�h
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_validate_item'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�K�{�`�F�b�N
    IF ( iv_null = gv_must_item ) THEN
      IF( iv_item_value IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_input
                       ,iv_token_name1  => gv_t_row_num
                       ,iv_token_value1 => in_row_num
                       ,iv_token_name2  => gv_t_column
                       ,iv_token_value2 => iv_item_name
                       ,iv_token_name3  => gv_t_item
                       ,iv_token_value3 => iv_file_data
                     );
        output_disp(
           iv_errmsg  => lv_errmsg
          ,iv_errbuf  => lv_errbuf
        );
        ov_retcode := gv_status_warn;
      END IF;
    ELSIF ( iv_null = gv_null_item ) THEN
      IF ( iv_item_value IS NOT NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_set_err
                       ,iv_token_name1  => gv_t_row_num
                       ,iv_token_value1 => in_row_num
                       ,iv_token_name2  => gv_t_column
                       ,iv_token_value2 => iv_item_name
                       ,iv_token_name3  => gv_t_item
                       ,iv_token_value3 => iv_file_data
                     );
        output_disp(
           iv_errmsg  => lv_errmsg
          ,iv_errbuf  => lv_errbuf
        );
        ov_retcode := gv_status_warn;
      END IF;
    ELSE
      NULL;
    END IF;
    --NUMBER�^�`�F�b�N
    IF ( ( iv_number IS NOT NULL ) AND ( iv_item_value IS NOT NULL ) ) THEN
      IF ( xxcop_common_pkg.chk_number_format( iv_item_value ) = FALSE ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_nchk
                       ,iv_token_name1  => gv_t_row_num
                       ,iv_token_value1 => in_row_num
                       ,iv_token_name2  => gv_t_column
                       ,iv_token_value2 => iv_item_name
                       ,iv_token_name3  => gv_t_item
                       ,iv_token_value3 => iv_file_data
                     );
        output_disp(
           iv_errmsg  => lv_errmsg
          ,iv_errbuf  => lv_errbuf
        );
        ov_retcode := gv_status_warn;
      END IF;
    END IF;
    --DATE�^�`�F�b�N
    IF ( ( iv_date IS NOT NULL ) AND ( iv_item_value IS NOT NULL ) ) THEN
      IF ( xxcop_common_pkg.chk_date_format( iv_item_value,iv_date ) = FALSE ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_dchk
                       ,iv_token_name1  => gv_t_row_num
                       ,iv_token_value1 => in_row_num
                       ,iv_token_name2  => gv_t_column
                       ,iv_token_value2 => iv_item_name
                       ,iv_token_name3  => gv_t_item
                       ,iv_token_value3 => iv_file_data
                     );
        output_disp(
           iv_errmsg  => lv_errmsg
          ,iv_errbuf  => lv_errbuf
        );
        ov_retcode := gv_status_warn;
      END IF;
    END IF;
    --�T�C�Y�`�F�b�N
    IF ( ( in_item_size IS NOT NULL ) AND ( iv_item_value IS NOT NULL ) ) THEN
      IF ( LENGTHB(iv_item_value) > in_item_size ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_schk
                       ,iv_token_name1  => gv_t_row_num
                       ,iv_token_value1 => in_row_num
                       ,iv_token_name2  => gv_t_column
                       ,iv_token_value2 => iv_item_name
                       ,iv_token_name3  => gv_t_item
                       ,iv_token_value3 => iv_file_data
                     );
        output_disp(
           iv_errmsg  => lv_errmsg
          ,iv_errbuf  => lv_errbuf
        );
        ov_retcode := gv_status_warn;
      END IF;
    END IF;
    --��v�敪�ޑ��݃`�F�b�N
    
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_validate_item;
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
--
  PROCEDURE init(
    iv_format       IN  VARCHAR2,   --   �t�H�[�}�b�g�p�^�[��
    od_base_date    OUT DATE,       --   �m���
    ov_errbuf       OUT VARCHAR2,   --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,   --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
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
    cv_quick_type     CONSTANT VARCHAR2(100) := 'XXCOP1_SCHEDULE_TYPE';   -- �^�C�v
    cv_quick_lang     CONSTANT VARCHAR2(100) := USERENV('LANG');          -- ����
    cv_quick_enable   CONSTANT VARCHAR2(1)   := 'Y';                      -- �L���t���O
    cd_sysdate        CONSTANT DATE          := TRUNC(SYSDATE);           -- �V�X�e�����t�i�N�����j
    -- *** ���[�J���ϐ� ***
    lv_quick_code     fnd_lookup_values.lookup_code%TYPE;                 -- �N�C�b�N�R�[�h
    lv_add_base_date  VARCHAR2(100);                                      -- �m��������
    lv_err_flg        VARCHAR2(1);                                        -- �G���[����
    -- *** ���[�J��RECORD�^ ***
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J��TABLE�^ ***
    -- *** ���[�J��PL/SQL�\ ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J����O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
  ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    lv_err_flg := gv_status_normal;
    --
    --1.�t�H�[�}�b�g�`�F�b�N
    BEGIN
      SELECT flv.lookup_code
      INTO   lv_quick_code
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type   = cv_quick_type
      AND    flv.language      = cv_quick_lang
      AND    flv.description   = iv_format
      AND    flv.enabled_flag  = cv_quick_enable
      AND    cd_sysdate BETWEEN NVL(flv.start_date_active,cd_sysdate)
                            AND NVL(flv.end_date_active  ,cd_sysdate)
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_Param
                       ,iv_token_name1  => gv_t_parameter
                       ,iv_token_value1 => '���̓p�����[�^'
                       ,iv_token_name2  => gv_t_value
                       ,iv_token_value2 => iv_format
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    --2.�m���������̎擾�E�`�F�b�N
    --lv_add_base_date := FND_PROFILE.VALUE(gv_p_base_date);
    FND_PROFILE.GET(gv_p_base_date,lv_add_base_date);
    --���f�o�b�O���O�i�J���p�j
    xxcop_common_pkg.put_debug_message('���m�������� �F ' || lv_add_base_date,gv_debug_mode);
    --
    --�G���[����
    IF ( lv_add_base_date IS NULL ) THEN
      lv_err_flg := gv_status_error;
    ELSE
      IF ( xxcop_common_pkg.chk_number_format( lv_add_base_date ) = FALSE ) THEN
        lv_err_flg := gv_status_error;
      ELSE
        od_base_date := cd_sysdate + lv_add_base_date;
        --���f�o�b�O���O�i�J���p�j
        xxcop_common_pkg.put_debug_message('���m��� �F ' || od_base_date,gv_debug_mode);
        --
      END IF;
    END IF;
    --
    IF ( lv_err_flg = gv_status_error ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_xxcop
                     ,iv_name         => gv_m_e_get_pro
                     ,iv_token_name1  => gv_t_prof_name
                     ,iv_token_value1 => '�m��������'
                   );
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
  END init;
--
--  
  /**********************************************************************************
   * Procedure Name   : get_file_info
   * Description      : �֘A�f�[�^�擾(A-2)
   ***********************************************************************************/
--
  PROCEDURE get_file_info(
    in_file_id          IN  NUMBER,                                     -- FILE_ID
    iv_format           IN  VARCHAR2,                                   -- �t�H�[�}�b�g�p�^�[��
    ov_file_name        OUT xxccp_mrp_file_ul_interface.file_name%TYPE, -- �t�@�C����
    ov_errbuf           OUT VARCHAR2,                                   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,                                   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)                                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_file_info'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lv_upload_name       fnd_lookup_values.meaning%TYPE;                  -- �t�@�C���A�b�v���[�h����
    lv_file_name         xxccp_mrp_file_ul_interface.file_name%TYPE;      -- �t�@�C����
    ld_upload_date       xxccp_mrp_file_ul_interface.creation_date%TYPE;  -- �A�b�v���[�h����
    -- *** ���[�J��RECORD�^ ***
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J��TABLE�^ ***
    -- *** ���[�J��PL/SQL�\ ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J����O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
  ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�t�@�C���A�b�v���[�hI/F�e�[�u���̏��擾
    xxcop_common_pkg.get_upload_table_info(
       in_file_id      => in_file_id      -- �t�@�C��ID
      ,iv_format       => iv_format       -- �t�H�[�}�b�g�p�^�[��
      ,ov_upload_name  => lv_upload_name  -- �t�@�C���A�b�v���[�h����
      ,ov_file_name    => lv_file_name    -- �t�@�C����
      ,od_upload_date  => ld_upload_date  -- �A�b�v���[�h����
      ,ov_retcode      => lv_retcode      -- ���^�[���R�[�h
      ,ov_errbuf       => lv_errbuf       -- �G���[�o�b�t�@
      ,ov_errmsg       => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    --�A�b�v���[�h���o��
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => gv_xxcop
                   ,iv_name         => gv_m_n_up_f_info
                   ,iv_token_name1  => gv_t_file_id
                   ,iv_token_value1 => TO_CHAR(in_file_id)
                   ,iv_token_name2  => gv_t_format_ptn
                   ,iv_token_value2 => iv_format
                   ,iv_token_name3  => gv_t_upload_obj
                   ,iv_token_value3 => lv_upload_name
                   ,iv_token_name4  => gv_t_file_name
                   ,iv_token_value4 => lv_file_name
                 );
    output_disp(
       iv_errmsg  => lv_errmsg
      ,iv_errbuf  => lv_errmsg
    );
    --
    --�󔒍s��}��
    lv_errmsg := gv_blank;
    output_disp(
       iv_errmsg  => lv_errmsg
      ,iv_errbuf  => lv_errmsg
    );
    --
    --�t�@�C���A�b�v���[�hI/F�e�[�u���̏��擾�Ɏ��s�����ꍇ
    IF ( lv_retcode <> gv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_xxcop
                     ,iv_name         => gv_m_e_get_f_info
                     ,iv_token_name1  => gv_t_fileid
                     ,iv_token_value1 => TO_CHAR(in_file_id)
                     ,iv_token_name2  => gv_t_format
                     ,iv_token_value2 => iv_format
                   );
      RAISE global_api_expt;
    END IF;
    --
    --�t�@�C�����Z�b�g
    ov_file_name := lv_file_name;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
  END get_file_info;
--
--
  /**********************************************************************************
   * Procedure Name   : get_upload_data
   * Description      : �t�@�C���A�b�v���[�hI/F�e�[�u���f�[�^���o(A-3)
   ***********************************************************************************/
--
  PROCEDURE get_upload_data(
    in_file_id    IN  NUMBER,                              -- FILE_ID
    o_fuid_tab    OUT xxccp_common_pkg2.g_file_data_tbl,   -- �t�@�C���A�b�v���[�hI/F�f�[�^(VARCHAR2�^)
    ov_errbuf     OUT VARCHAR2,                            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,                            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_data'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J��RECORD�^ ***
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J��TABLE�^ ***
    -- *** ���[�J��PL/SQL�\ ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J����O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
  ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --1.�t�@�C���f�[�^�擾(BLOB�f�[�^�ϊ�)
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => in_file_id         -- �t�@�C��ID
      ,ov_file_data => o_fuid_tab         -- �t�@�C���A�b�v���[�hI/F�f�[�^(VARCHAR2�^)
      ,ov_errbuf    => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode   => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg    => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> gv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
    --�f�[�^�����̊m�F
    IF ( o_fuid_tab.COUNT <= gn_header_row_num ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_xxcop
                     ,iv_name         => gv_m_e_no_data
                   );
      RAISE global_process_expt;
    END IF;
    --�Ώی�����CSV���R�[�h���|�w�b�_�[�s���ŃZ�b�g
    gn_target_cnt := o_fuid_tab.COUNT - gn_header_row_num;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
  END get_upload_data;
--
--
  /**********************************************************************************
   * Procedure Name   : chk_upload_data
   * Description      : �Ó����`�F�b�N(A-4)
   ***********************************************************************************/
--
  PROCEDURE chk_upload_data(
    iv_format     IN  VARCHAR2,                           -- �t�H�[�}�b�g�p�^�[��
    i_fuid_tab    IN  xxccp_common_pkg2.g_file_data_tbl,  -- �t�@�C���A�b�v���[�hI/F�f�[�^(VARCHAR2�^)
    --����2009/01/23 �ǉ�
    id_base_date  IN  DATE,                               -- �m���
    --����2009/01/23 �ǉ�
    o_scdl_tab    OUT xm_schedule_if_ttype,               -- ��v��f�[�^
    ov_errbuf     OUT VARCHAR2,                           -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,                           -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_upload_data'; -- �v���O������
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
    cv_quick_type     CONSTANT VARCHAR2(100) := 'XXCOP1_SCHEDULE_TYPE';          -- �^�C�v
    cv_quick_lang     CONSTANT VARCHAR2(100) := USERENV('LANG');                 -- ����
    cv_quick_enable   CONSTANT VARCHAR2(1)   := 'Y';                             -- �L���t���O
    cd_quick_sysdate  CONSTANT DATE          := TRUNC(SYSDATE);                  -- �V�X�e�����t�i�N�����j
    cd_sysdate        CONSTANT DATE          := TRUNC(SYSDATE);                  -- �V�X�e�����t�i�N�����j    
    -- *** ���[�J���ϐ� ***
    l_csv_tab         xxcop_common_pkg.g_char_ttype;                             -- UPLOAD�t�@�C���̍��ڕ�����f�[�^���i�[
    lv_invalid_flag   VARCHAR2(1);                                               -- �G���[���R�[�h�t���O
    ln_srd_idx        NUMBER;                                                    -- �����R�[�hNO
    ln_quick_rec_cnt  NUMBER;                                                    -- �N�C�b�N�R�[�h����
    ln_user_rec_cnt   NUMBER;                                                    -- ���[�U�[����
    l_item_id         mtl_system_items_b.inventory_item_id%TYPE;                 -- �i��ID
    l_org_id          mtl_parameters.organization_id%TYPE;                       -- �g�DID
--20090403_Ver1.1_T1_0237_SCS.Goto_MOD_START
--    l_org_code        xxcop.xxcop_mrp_schedule_interface.organization_code%TYPE; -- �g�D�R�[�h
    l_org_code        xxcop_mrp_schedule_interface.organization_code%TYPE;       -- �g�D�R�[�h
--20090403_Ver1.1_T1_0237_SCS.Goto_MOD_END
    lv_case_flg       VARCHAR2(4);                                               -- �����t�K�{���ڔ��ʗp
    l_date_flg        bom_calendar_dates.seq_num%TYPE;                           -- �ғ����t���O�i��ғ�����NULL�j
    lv_one_chk_flg    VARCHAR2(1);                                               -- ��Ӑ��L�[�`�F�b�N�t���O
    lv_token_col_name VARCHAR2(100);                                             -- ��Ӑ��L�[�`�F�b�N�t���O
    -- *** ���[�J��RECORD�^ ***
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J��TABLE�^ ***
    -- *** ���[�J��PL/SQL�\ ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J����O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
  ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�t�@�C���A�b�v���[�hI/F�e�[�u���̏��擾
    <<row_loop>>
    FOR ln_row_idx IN ( i_fuid_tab.FIRST + gn_header_row_num ) .. i_fuid_tab.COUNT LOOP
      --
      --���[�v���Ŏg�p����ϐ��̏�����
      lv_invalid_flag                             := gv_status_normal;
      ln_srd_idx                                  := ln_row_idx - gn_header_row_num;
      o_scdl_tab(ln_srd_idx).schedule_designator  := '';
      o_scdl_tab(ln_srd_idx).schedule_description := '';
      o_scdl_tab(ln_srd_idx).organization_code    := '';
      o_scdl_tab(ln_srd_idx).schedule_type        := '';
      o_scdl_tab(ln_srd_idx).item_code            := '';
      o_scdl_tab(ln_srd_idx).schedule_date        := '';
      o_scdl_tab(ln_srd_idx).schedule_quantity    := '';
      o_scdl_tab(ln_srd_idx).deliver_from         := '';
      o_scdl_tab(ln_srd_idx).shipment_date        := '';
      o_scdl_tab(ln_srd_idx).schedule_prod_flg    := '';
      --
      --CSV��������
      xxcop_common_pkg.char_delim_partition(
         iv_char      => i_fuid_tab(ln_row_idx)  -- �Ώە�����
        ,iv_delim     => gv_delim                -- �f���~�^
        ,o_char_tab   => l_csv_tab               -- ��������
        ,ov_retcode   => lv_retcode              -- ���^�[���R�[�h
        ,ov_errbuf    => lv_errbuf               -- �G���[�E���b�Z�[�W
        ,ov_errmsg    => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF ( lv_retcode <> gv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
      --
      -- ===============================
      -- 1.���ڐ��`�F�b�N
      -- ===============================
      IF ( l_csv_tab.COUNT = gn_column_num ) THEN
        -- ===============================
        -- �����ڑ����`�F�b�N
        --   2.�K�{�`�F�b�N
        --   3.NUMBER�^�`�F�b�N
        --   4.DATE�^�`�F�b�N
        --   5.�T�C�Y�`�F�b�N
        -- ===============================
        -- 
        -- -------------------------------
        -- �� FLD1 : MDS/MPS��
        --     �K�{�@  �F ��
        --     �^�C�v  : ����
        --     �T�C�Y  : 10byte
        -- -------------------------------
        check_validate_item(
           iv_item_name   => gv_column_name_01
          ,iv_item_value  => l_csv_tab(1)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_01
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_scdl_tab(ln_srd_idx).schedule_designator := SUBSTRB(l_csv_tab(1),1,gv_column_len_01);
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          lv_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --
        -- -------------------------------
        -- �� FLD2 : MDS/MPS�E�v
        --     �K�{�@  �F ��
        --     �^�C�v  : ����
        --     �T�C�Y  : 50byte
        -- -------------------------------
        check_validate_item(
           iv_item_name   => gv_column_name_02
          ,iv_item_value  => l_csv_tab(2)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_02
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_scdl_tab(ln_srd_idx).schedule_description := SUBSTRB(l_csv_tab(2),1,gv_column_len_02);
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          lv_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --
        -- -------------------------------
        -- ��2008/12/25 �ǉ�
        -- �� FLD3 : �g�D�R�[�h
        --     �K�{�@  �F ��
        --     �^�C�v  : ����
        --     �T�C�Y  : 3byte
        -- -------------------------------
        check_validate_item(
           iv_item_name   => gv_column_name_03
          ,iv_item_value  => l_csv_tab(3)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_03
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_scdl_tab(ln_srd_idx).organization_code := SUBSTRB(l_csv_tab(3),1,gv_column_len_03);
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          lv_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --
        -- -------------------------------
        -- �� FLD4 : ��v�敪��
        --     �K�{�@  �F ��
        --     �^�C�v  : ����
        --     �T�C�Y  : 1byte
        -- -------------------------------
        check_validate_item(
           iv_item_name   => gv_column_name_04
          ,iv_item_value  => l_csv_tab(4)
          ,iv_null        => gv_must_item
          ,iv_number      => gv_any_item
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_04
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_scdl_tab(ln_srd_idx).schedule_type := TO_NUMBER(l_csv_tab(4));
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          lv_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --
        -- -------------------------------
        -- �� FLD5 : �i�ڃR�[�h
        --     �K�{�@  �F ��
        --     �^�C�v  : ����
        --     �T�C�Y  : 7byte
        -- -------------------------------
        check_validate_item(
           iv_item_name   => gv_column_name_05
          ,iv_item_value  => l_csv_tab(5)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_05
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_scdl_tab(ln_srd_idx).item_code := SUBSTRB(l_csv_tab(5),1,gv_column_len_05);
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          lv_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --
        -- -------------------------------
        -- �� FLD6 : �v����t
        --     �K�{�@  �F ��
        --     �^�C�v  : ���t
        --     �T�C�Y  :  -
        -- -------------------------------
        check_validate_item(
           iv_item_name   => gv_column_name_06
          ,iv_item_value  => l_csv_tab(6)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => gv_ymd_format
          ,in_item_size   => NULL
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_scdl_tab(ln_srd_idx).schedule_date := TO_DATE(l_csv_tab(6),gv_ymd_format);
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          lv_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --
        -- -------------------------------
        -- �� FLD7 : �v�搔��
        --     �K�{�@  �F ��
        --     �^�C�v  : ����
        --     �T�C�Y  :  -
        -- -------------------------------
        check_validate_item(
           iv_item_name   => gv_column_name_07
          ,iv_item_value  => l_csv_tab(7)
          ,iv_null        => gv_must_item
          ,iv_number      => gv_any_item
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_07
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_scdl_tab(ln_srd_idx).schedule_quantity := TO_NUMBER(l_csv_tab(7));
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          lv_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --
        -- -------------------------------
        -- �� FLD8 : �o�׌��q�ɃR�[�h
        --     �K�{�@  �F 
        --     �^�C�v  : ����
        --     �T�C�Y  : 3byte
        -- -------------------------------
        --�����t�K�{����
        IF ( iv_format = gv_format_mps_o ) THEN
          lv_case_flg := gv_must_item;
        ELSE
          lv_case_flg := gv_any_item;
        END IF;
        --
        check_validate_item(
           iv_item_name   => gv_column_name_08
          ,iv_item_value  => l_csv_tab(8)
          ,iv_null        => lv_case_flg          --�����t�K�{�t���O���Z�b�g
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_08
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_scdl_tab(ln_srd_idx).deliver_from := SUBSTRB(l_csv_tab(8),1,gv_column_len_08);
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          lv_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --
        -- -------------------------------
        -- �� FLD9 : �o�ד�
        --     �K�{�@  �F 
        --     �^�C�v  : ���t
        --     �T�C�Y  :  -
        -- -------------------------------
        --�����t�K�{����
        IF ( iv_format = gv_format_mps_o ) THEN
          lv_case_flg := gv_must_item;
        ELSE
          lv_case_flg := gv_any_item;
        END IF;
        --
        check_validate_item(
           iv_item_name   => gv_column_name_09
          ,iv_item_value  => l_csv_tab(9)
          ,iv_null        => lv_case_flg
          ,iv_number      => NULL
          ,iv_date        => gv_ymd_format
          ,in_item_size   => NULL
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_scdl_tab(ln_srd_idx).shipment_date := TO_DATE(l_csv_tab(9),gv_ymd_format);
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          lv_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --
        -- -------------------------------
        -- �� FLD10: �v�揤�i�t���O
        --     �K�{�@  �F 
        --     �^�C�v  : ����
        --     �T�C�Y  : 1byte
        -- -------------------------------
        check_validate_item(
           iv_item_name   => gv_column_name_10
          ,iv_item_value  => l_csv_tab(10)
          ,iv_null        => gv_any_item
          ,iv_number      => gv_any_item
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_10
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_scdl_tab(ln_srd_idx).schedule_prod_flg := TO_NUMBER(l_csv_tab(10));
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          lv_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
      --���f�o�b�O���O�i�J���p�j
      xxcop_common_pkg.put_debug_message(ln_srd_idx || '�s��' || ':1-fld10:' || 'b',gv_debug_mode);
      --
        --
        -- ===============================
        -- 6.�g�D�R�[�h���݃`�F�b�N
        -- ===============================
        BEGIN
          SELECT mp.organization_code
          INTO   l_org_code
          FROM   mtl_parameters                 mp                                -- �g�D�p�����[�^
          WHERE  mp.organization_code = o_scdl_tab(ln_srd_idx).organization_code  -- CSV�t�@�C���́u�g�D�R�[�h�v
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_xxcop
                           ,iv_name         => gv_m_e_not_exist
                           ,iv_token_name1  => gv_t_row_num
                           ,iv_token_value1 => ln_srd_idx
                           ,iv_token_name2  => gv_t_column
                           ,iv_token_value2 => gv_column_name_03
                           ,iv_token_name3  => gv_t_value1
                           ,iv_token_value3 => l_csv_tab(3)
                           ,iv_token_name4  => gv_t_table
                           ,iv_token_value4 => gv_table_name_org
                           ,iv_token_name5  => gv_t_item
                           ,iv_token_value5 => i_fuid_tab(ln_row_idx)
                         );
            output_disp(
               iv_errmsg  => lv_errmsg
              ,iv_errbuf  => lv_errbuf
            );
            lv_invalid_flag := gv_status_error;
          WHEN TOO_MANY_ROWS THEN
            null;
        END;
        --
        --l_org_code := '';
        --
        -- =================================
        -- 7.�g�D�R�[�h�E��v�於�������`�F�b�N
        -- =================================
        BEGIN
          SELECT mp.organization_code                               -- �g�D�R�[�h
          INTO   l_org_code
          FROM   mtl_parameters                 mp                  -- �g�D�p�����[�^
                ,mrp_schedule_designators       msd                 -- ��v�於�e�[�u��
          WHERE  mp.organization_code    = o_scdl_tab(ln_srd_idx).organization_code   --CSV�t�@�C���́u�g�D�R�[�h�v
          AND    mp.organization_id      = msd.organization_id
          AND    msd.schedule_designator = o_scdl_tab(ln_srd_idx).schedule_designator --CSV�t�@�C���́uMDS/MPS���v
          --����2009/01/19 �ǉ�
          AND    msd.attribute1          = o_scdl_tab(ln_srd_idx).schedule_type       --CSV�t�@�C���́u��v�敪�ށv
          --����2009/01/19 �ǉ�
          AND    NVL(msd.disable_date , cd_sysdate + 1) > cd_sysdate                  --��v�於�e�[�u���̗L�����`�F�b�N
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_xxcop
                           ,iv_name         => gv_m_e_unmatch
                           ,iv_token_name1  => gv_t_row_num
                           ,iv_token_value1 => ln_srd_idx
                           ,iv_token_name2  => gv_t_schedule_name
                           ,iv_token_value2 => l_csv_tab(1)
                           ,iv_token_name3  => gv_t_org_code
                           ,iv_token_value3 => l_csv_tab(3)
                           ,iv_token_name4  => gv_t_item
                           ,iv_token_value4 => i_fuid_tab(ln_row_idx)
                         );
            output_disp(
               iv_errmsg  => lv_errmsg
              ,iv_errbuf  => lv_errbuf
            );
            lv_invalid_flag := gv_status_error;
          WHEN TOO_MANY_ROWS THEN
            null;
        END;
        --
--20090403_Ver1.1_T1_0237_SCS.Goto_DEL_START
--        -- ===============================
--        -- 8.�N�����[�U�[�`�F�b�N
--        -- ===============================
--        SELECT count(fu.user_id)
--        INTO   ln_user_rec_cnt
--        FROM   fnd_user                  fu                     -- ���[�U�[�}�X�^
--              ,per_all_people_f          papf                   -- �]�ƈ��}�X�^
--              ,mtl_item_locations        mil                    -- OPM�ۊǏꏊ�}�X�^
--              ,mrp_schedule_designators  msd                    -- ��v�於�e�[�u��
--              ,po_vendors                pv                     -- �d����}�X�^
--              ,mtl_parameters            mp                     -- �g�D�p�����[�^
--        WHERE  fu.employee_id       = papf.person_id
--        AND    papf.attribute4      = pv.segment1                                    --�]�ƈ�.�d����R�[�h = �d����.�d����R�[�h
--        AND    pv.segment1          = mil.attribute13                                --�d����.�d����R�[�h = OPM�ۊǏꏊ.�d����R�[�h
--        AND    mil.organization_id  = msd.organization_id                            --OPM�ۊǏꏊ.�݌ɑg�DID = ��v�於.�݌ɑg�DID
--        AND    msd.organization_id  = mp.organization_id                             --��v�於.�݌ɑg�DID = �g�D�p�����[�^.�g�DID
--        AND    mp.organization_code = o_scdl_tab(ln_srd_idx).organization_code       --�g�D�p�����[�^.�g�D�R�[�h = CSV�t�@�C��.�g�D�R�[�h
--        AND    fu.user_id           = gn_user_id                                     --�R���J�����g�N�����[�U�[
--        AND    cd_sysdate BETWEEN NVL(papf.effective_start_date,cd_sysdate)          --�]�ƈ��}�X�^�̗L�����`�F�b�N
--                              AND NVL(papf.effective_end_date  ,cd_sysdate)
--        AND    msd.schedule_designator = o_scdl_tab(ln_srd_idx).schedule_designator  --CSV�t�@�C��.MDS/MPS��
--        AND    pv.enabled_flag         = 'Y'                                         --�d����}�X�^�̗L���t���O�`�F�b�N
--        AND    NVL(mil.disable_date , cd_sysdate) >= cd_sysdate                      --OPM�ۊǏꏊ�}�X�^�̗L�����`�F�b�N
--        AND    NVL(msd.disable_date , cd_sysdate + 1) > cd_sysdate                   --��v�於�e�[�u���̗L�����`�F�b�N
--        ;
--        --
--        IF ( ln_user_rec_cnt = 0 ) THEN
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                          iv_application  => gv_xxcop
--                         ,iv_name         => gv_m_e_user_chk
--                         ,iv_token_name1  => gv_t_row_num
--                         ,iv_token_value1 => ln_srd_idx
--                         ,iv_token_name2  => gv_t_schedule_name
--                         ,iv_token_value2 => l_csv_tab(1)
--                       );
--          output_disp(
--             iv_errmsg  => lv_errmsg
--            ,iv_errbuf  => lv_errbuf
--          );
--          lv_invalid_flag := gv_status_error;
--        END IF;
--        --
--20090403_Ver1.1_T1_0237_SCS.Goto_DEL_END
        -- ===============================
        -- 9.��v�敪�ޑ��݃`�F�b�N
        -- ===============================
        SELECT count(flv.enabled_flag)
        INTO   ln_quick_rec_cnt
        FROM   fnd_lookup_values flv
        WHERE  flv.lookup_type   = cv_quick_type
        AND    flv.language      = cv_quick_lang
        AND    flv.description   = iv_format
        AND    flv.lookup_code   = o_scdl_tab(ln_srd_idx).schedule_type
        AND    flv.enabled_flag  = cv_quick_enable
        AND    cd_quick_sysdate BETWEEN NVL(flv.start_date_active,cd_quick_sysdate)
                                    AND NVL(flv.end_date_active  ,cd_quick_sysdate)
        ;
        IF ( ln_quick_rec_cnt = 0 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => gv_xxcop
                         ,iv_name         => gv_m_e_set_err_t
                         ,iv_token_name1  => gv_t_row_num
                         ,iv_token_value1 => ln_srd_idx
                         ,iv_token_name2  => gv_t_item
                         ,iv_token_value2 => i_fuid_tab(ln_row_idx)
                       );
          output_disp(
             iv_errmsg  => lv_errmsg
            ,iv_errbuf  => lv_errbuf
          );
          lv_invalid_flag := gv_status_error;
        END IF;
      --���f�o�b�O���O�i�J���p�j
      xxcop_common_pkg.put_debug_message(ln_srd_idx || '�s��' || ':6:' || 'b',gv_debug_mode);
      --
        --
        -- ===============================
        -- 10.�֎~���ړ��̓`�F�b�N
        -- ===============================
        CASE iv_format
          -- 201:��v��i�o�ח\��MDS�j
          WHEN gv_format_mds_o THEN
            --FLD8:�o�׌��q�ɃR�[�h
            IF ( o_scdl_tab(ln_srd_idx).deliver_from IS NOT NULL ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_xxcop
                             ,iv_name         => gv_m_e_set_err
                             ,iv_token_name1  => gv_t_row_num
                             ,iv_token_value1 => ln_srd_idx
                             ,iv_token_name2  => gv_t_column
                             ,iv_token_value2 => gv_column_name_08
                             ,iv_token_name3  => gv_t_item
                             ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                           );
              output_disp(
                 iv_errmsg  => lv_errmsg
                ,iv_errbuf  => lv_errbuf
              );
              lv_invalid_flag := gv_status_error;
            END IF;
            --FLD9:�o�ד�
            IF ( o_scdl_tab(ln_srd_idx).shipment_date IS NOT NULL ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_xxcop
                             ,iv_name         => gv_m_e_set_err
                             ,iv_token_name1  => gv_t_row_num
                             ,iv_token_value1 => ln_srd_idx
                             ,iv_token_name2  => gv_t_column
                             ,iv_token_value2 => gv_column_name_09
                             ,iv_token_name3  => gv_t_item
                             ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                           );
              output_disp(
                 iv_errmsg  => lv_errmsg
                ,iv_errbuf  => lv_errbuf
              );
              lv_invalid_flag := gv_status_error;
            END IF;
            --
          -- 202:��v��i�H��o�׌v��MPS�j
          WHEN gv_format_mps_o THEN
            -- FLD10:�v�揤�i�t���O
            IF ( o_scdl_tab(ln_srd_idx).schedule_prod_flg IS NOT NULL ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_xxcop
                             ,iv_name         => gv_m_e_set_err
                             ,iv_token_name1  => gv_t_row_num
                             ,iv_token_value1 => ln_srd_idx
                             ,iv_token_name2  => gv_t_column
                             ,iv_token_value2 => gv_column_name_10
                             ,iv_token_name3  => gv_t_item
                             ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                           );
              output_disp(
                 iv_errmsg  => lv_errmsg
                ,iv_errbuf  => lv_errbuf
              );
              lv_invalid_flag := gv_status_error;
            END IF;
            --
          -- 203:��v��i�w���v��MPS�j
          WHEN gv_format_mps_i THEN
            --FLD8:�o�׌��q�ɃR�[�h
            IF ( o_scdl_tab(ln_srd_idx).deliver_from IS NOT NULL ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_xxcop
                             ,iv_name         => gv_m_e_set_err
                             ,iv_token_name1  => gv_t_row_num
                             ,iv_token_value1 => ln_srd_idx
                             ,iv_token_name2  => gv_t_column
                             ,iv_token_value2 => gv_column_name_08
                             ,iv_token_name3  => gv_t_item
                             ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                           );
              output_disp(
                 iv_errmsg  => lv_errmsg
                ,iv_errbuf  => lv_errbuf
              );
              lv_invalid_flag := gv_status_error;
            END IF;
            --FLD9:�o�ד�
            IF ( o_scdl_tab(ln_srd_idx).shipment_date IS NOT NULL ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_xxcop
                             ,iv_name         => gv_m_e_set_err
                             ,iv_token_name1  => gv_t_row_num
                             ,iv_token_value1 => ln_srd_idx
                             ,iv_token_name2  => gv_t_column
                             ,iv_token_value2 => gv_column_name_09
                             ,iv_token_name3  => gv_t_item
                             ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                           );
              output_disp(
                 iv_errmsg  => lv_errmsg
                ,iv_errbuf  => lv_errbuf
              );
              lv_invalid_flag := gv_status_error;
            END IF;
            -- FLD10:�v�揤�i�t���O
            IF ( o_scdl_tab(ln_srd_idx).schedule_prod_flg IS NOT NULL ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_xxcop
                             ,iv_name         => gv_m_e_set_err
                             ,iv_token_name1  => gv_t_row_num
                             ,iv_token_value1 => ln_srd_idx
                             ,iv_token_name2  => gv_t_column
                             ,iv_token_value2 => gv_column_name_10
                             ,iv_token_name3  => gv_t_item
                             ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                           );
              output_disp(
                 iv_errmsg  => lv_errmsg
                ,iv_errbuf  => lv_errbuf
              );
              lv_invalid_flag := gv_status_error;
            END IF;
        END CASE;
      --���f�o�b�O���O�i�J���p�j
      xxcop_common_pkg.put_debug_message(ln_srd_idx || '�s��' || ':7:' || 'b',gv_debug_mode);
      --
        --
        -- ===============================
        -- 11.�i�ڃR�[�h�`�F�b�N
        -- ===============================
        BEGIN
          SELECT msib.inventory_item_id
          INTO   l_item_id
          FROM   mtl_system_items_b        msib               -- Disc�i�ڃ}�X�^
                ,mrp_schedule_designators  msde               -- ��v�於
                --����2009/01/16 �ǉ�
                ,mtl_parameters            mp                 -- �g�D�p�����[�^
                --����2009/01/16 �ǉ�
          WHERE  msib.segment1            = o_scdl_tab(ln_srd_idx).item_code
          --����2009/01/16 �ǉ�
          AND    mp.organization_code     = o_scdl_tab(ln_srd_idx).organization_code
          AND    msib.organization_id     = mp.organization_id
          --����2009/01/16 �ǉ�
          AND    msib.inventory_item_status_code <> 'Inactive'
          AND    msib.organization_id     = msde.organization_id
          AND    msde.schedule_designator = o_scdl_tab(ln_srd_idx).schedule_designator
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_xxcop
                           ,iv_name         => gv_m_e_not_exist
                           ,iv_token_name1  => gv_t_row_num
                           ,iv_token_value1 => ln_srd_idx
                           ,iv_token_name2  => gv_t_column
                           ,iv_token_value2 => gv_column_name_05
                           ,iv_token_name3  => gv_t_value1
                           ,iv_token_value3 => l_csv_tab(5)
                           ,iv_token_name4  => gv_t_table
                           ,iv_token_value4 => gv_table_name_item
                           ,iv_token_name5  => gv_t_item
                           ,iv_token_value5 => i_fuid_tab(ln_row_idx)
                         );
            output_disp(
               iv_errmsg  => lv_errmsg
              ,iv_errbuf  => lv_errbuf
            );
            lv_invalid_flag := gv_status_error;
          WHEN TOO_MANY_ROWS THEN
            null;
        END;
      --���f�o�b�O���O�i�J���p�j
      xxcop_common_pkg.put_debug_message(ln_srd_idx || '�s��' || ':8:' || 'b',gv_debug_mode);
      --
--20090403_Ver1.1_T1_0270_SCS.Goto_ADD_START
        -- ===============================
        -- 11.OPM�i�ڃ}�X�^�`�F�b�N
        -- ===============================
        BEGIN
          SELECT NVL(TO_NUMBER(iimb.attribute11), 1)
          INTO   o_scdl_tab(ln_srd_idx).num_of_cases
          FROM   ic_item_mst_b             iimb               -- OPM�i�ڃ}�X�^
          WHERE  iimb.item_no          = o_scdl_tab(ln_srd_idx).item_code
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_xxcop
                           ,iv_name         => gv_m_e_not_exist
                           ,iv_token_name1  => gv_t_row_num
                           ,iv_token_value1 => ln_srd_idx
                           ,iv_token_name2  => gv_t_column
                           ,iv_token_value2 => gv_column_name_05
                           ,iv_token_name3  => gv_t_value1
                           ,iv_token_value3 => l_csv_tab(5)
                           ,iv_token_name4  => gv_t_table
                           ,iv_token_value4 => gv_table_name_opm
                           ,iv_token_name5  => gv_t_item
                           ,iv_token_value5 => i_fuid_tab(ln_row_idx)
                         );
            output_disp(
               iv_errmsg  => lv_errmsg
              ,iv_errbuf  => lv_errbuf
            );
            lv_invalid_flag := gv_status_error;
        END;
--20090403_Ver1.1_T1_0270_SCS.Goto_ADD_END
        --
        -- ===============================
        -- 12.�v����t�E�ғ����`�F�b�N
        -- ===============================
        --����2009/01/23 �ǉ�
        --�X�L�b�v���� [�v����t > �m���]
        IF o_scdl_tab(ln_srd_idx).schedule_date > id_base_date THEN
        --����2009/01/23 �ǉ�
          BEGIN
            SELECT bcd.seq_num
            INTO   l_date_flg
            FROM   bom_calendar_dates  bcd          --�ғ����J�����_
                  ,mtl_parameters      mp           --�g�D�p�����[�^
            WHERE  mp.organization_code = o_scdl_tab(ln_srd_idx).organization_code
            AND    bcd.calendar_code    = mp.calendar_code
            AND    bcd.calendar_date    = o_scdl_tab(ln_srd_idx).schedule_date
            ;
            IF l_date_flg IS NULL THEN              --��ғ����i�y�E���j
              RAISE NO_DATA_FOUND;
            END IF;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_xxcop
                             ,iv_name         => gv_m_e_calendar_err
                             ,iv_token_name1  => gv_t_row_num
                             ,iv_token_value1 => ln_srd_idx
                             ,iv_token_name2  => gv_t_date
                             ,iv_token_value2 => TO_CHAR(o_scdl_tab(ln_srd_idx).schedule_date,'YYYY/MM/DD')
                           );
              output_disp(
                 iv_errmsg  => lv_errmsg
                ,iv_errbuf  => lv_errbuf
              );
              lv_invalid_flag := gv_status_error;
            WHEN TOO_MANY_ROWS THEN
              null;
          END;
        --����2009/01/23 �ǉ�
        END IF;
        --����2009/01/23 �ǉ�
        --
        -- ===============================
        -- 13.�o�Ɍ��q�ɃR�[�h���݃`�F�b�N
        -- ===============================
        IF ( iv_format = gv_format_mps_o ) THEN
          BEGIN
            SELECT mp.organization_id
            INTO   l_org_id
            FROM   mtl_parameters  mp                     --�g�D�p�����[�^
            WHERE  mp.organization_code = o_scdl_tab(ln_srd_idx).deliver_from
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_xxcop
                             ,iv_name         => gv_m_e_not_exist
                             ,iv_token_name1  => gv_t_row_num
                             ,iv_token_value1 => ln_srd_idx
                             ,iv_token_name2  => gv_t_column
                             ,iv_token_value2 => gv_column_name_08
                             ,iv_token_name3  => gv_t_value1
                             ,iv_token_value3 => l_csv_tab(8)
                             ,iv_token_name4  => gv_t_table
                             ,iv_token_value4 => gv_table_name_org
                             ,iv_token_name5  => gv_t_item
                             ,iv_token_value5 => i_fuid_tab(ln_row_idx)
                           );
              output_disp(
                 iv_errmsg  => lv_errmsg
                ,iv_errbuf  => lv_errbuf
              );
              lv_invalid_flag := gv_status_error;
            WHEN TOO_MANY_ROWS THEN
              null;
          END;
        END IF;
      --���f�o�b�O���O�i�J���p�j
      xxcop_common_pkg.put_debug_message(ln_srd_idx || '�s��' || ':9:' || 'b',gv_debug_mode);
      --
        --
        -- ===============================
        -- 14.�v�揤�i�t���O�s���`�F�b�N
        -- ===============================
        IF ( iv_format = gv_format_mds_o
          AND o_scdl_tab(ln_srd_idx).schedule_prod_flg <> 1
          AND o_scdl_tab(ln_srd_idx).schedule_prod_flg IS NOT NULL )
        THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => gv_xxcop
                         ,iv_name         => gv_m_e_chk_err
                         ,iv_token_name1  => gv_t_row_num
                         ,iv_token_value1 => ln_srd_idx
                         ,iv_token_name2  => gv_t_column
                         ,iv_token_value2 => gv_column_name_10
                         ,iv_token_name3  => gv_t_item
                         ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                       );
          output_disp(
             iv_errmsg  => lv_errmsg
            ,iv_errbuf  => lv_errbuf
          );
          lv_invalid_flag := gv_status_error;
        END IF;
      --���f�o�b�O���O�i�J���p�j
      xxcop_common_pkg.put_debug_message(ln_srd_idx || '�s��' || ':10:' || 'b',gv_debug_mode);
      --
        --
        -- ===============================
        -- 15.��ӃL�[�`�F�b�N
        -- ===============================
        <<key_loop>>
        FOR ln_key_idx IN o_scdl_tab.first .. ( ln_srd_idx - 1 ) LOOP
        --
          -- �G���[�t���O������
          lv_one_chk_flg := '0';
          -- ��Ӑ��G���[���o
          CASE iv_format
            --����2009/01/20 �ǉ�
            -- 202:��v��i�H��o�׌v��MPS�j
            WHEN gv_format_mps_o THEN
              IF (  o_scdl_tab(ln_srd_idx).schedule_designator   = o_scdl_tab(ln_key_idx).schedule_designator
                AND o_scdl_tab(ln_srd_idx).schedule_description  = o_scdl_tab(ln_key_idx).schedule_description
                AND o_scdl_tab(ln_srd_idx).organization_code     = o_scdl_tab(ln_key_idx).organization_code
                AND o_scdl_tab(ln_srd_idx).item_code             = o_scdl_tab(ln_key_idx).item_code
                AND o_scdl_tab(ln_srd_idx).schedule_date         = o_scdl_tab(ln_key_idx).schedule_date
                AND o_scdl_tab(ln_srd_idx).deliver_from          = o_scdl_tab(ln_key_idx).deliver_from )
              THEN
                lv_one_chk_flg := '1';
                lv_token_col_name := gv_column_name_01 || gv_msg_comma
                                  || gv_column_name_02 || gv_msg_comma
                                  || gv_column_name_03 || gv_msg_comma
                                  || gv_column_name_05 || gv_msg_comma
                                  || gv_column_name_06 || gv_msg_comma
                                  || gv_column_name_08 || gv_msg_comma ;
              END IF;
            --����2009/01/20 �ǉ�
            --
            -- 201:�o�ח\��,203:�w���v��
            ELSE
              IF (  o_scdl_tab(ln_srd_idx).schedule_designator   = o_scdl_tab(ln_key_idx).schedule_designator
                AND o_scdl_tab(ln_srd_idx).schedule_description  = o_scdl_tab(ln_key_idx).schedule_description
                AND o_scdl_tab(ln_srd_idx).organization_code     = o_scdl_tab(ln_key_idx).organization_code
                AND o_scdl_tab(ln_srd_idx).item_code             = o_scdl_tab(ln_key_idx).item_code
                AND o_scdl_tab(ln_srd_idx).schedule_date         = o_scdl_tab(ln_key_idx).schedule_date )
              THEN
                lv_one_chk_flg := '1';
                lv_token_col_name := gv_column_name_01 || gv_msg_comma
                                  || gv_column_name_02 || gv_msg_comma
                                  || gv_column_name_03 || gv_msg_comma
                                  || gv_column_name_05 || gv_msg_comma
                                  || gv_column_name_06 || gv_msg_comma ;
              END IF;
          END CASE;
          --
          -- �G���[�����b�Z�[�W�o��
          IF ( lv_one_chk_flg = '1' ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_xxcop
                           ,iv_name         => gv_m_e_1rec_chk
                           ,iv_token_name1  => gv_t_row_num
                           ,iv_token_value1 => ln_srd_idx
                           ,iv_token_name2  => gv_t_column
                           ,iv_token_value2 => lv_token_col_name
                           ,iv_token_name3  => gv_t_item
                           ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                         );
            output_disp(
               iv_errmsg  => lv_errmsg
              ,iv_errbuf  => lv_errbuf
            );
            lv_invalid_flag := gv_status_error;
          END IF;
        END LOOP key_loop;
        --
      --���f�o�b�O���O�i�J���p�j
      xxcop_common_pkg.put_debug_message(ln_srd_idx || '�s��' || ':11:' || 'b',gv_debug_mode);
      --
      ELSE
        --1�̃G���[����
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_fchk
                       ,iv_token_name1  => gv_t_row_num
                       ,iv_token_value1 => ln_srd_idx
                       ,iv_token_name2  => gv_t_file
                       ,iv_token_value2 => 'CSV�t�@�C��'
                       ,iv_token_name3  => gv_t_item
                       ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                     );
        output_disp(
           iv_errmsg  => lv_errmsg
          ,iv_errbuf  => lv_errbuf
        );
        lv_invalid_flag := gv_status_error;
      END IF;
      --
      IF ( lv_invalid_flag = gv_status_error ) THEN
        --�Ó����`�F�b�N�ŃG���[�ƂȂ����ꍇ�A�G���[�������J�E���g�i���R�[�h�P�ʂ�1���J�E���g����j
        gn_error_cnt := gn_error_cnt + 1;
        --ov_retcode := gv_status_error;
      END IF;
    END LOOP row_loop;
    --
    --
    IF ( gn_error_cnt > 0 OR lv_invalid_flag = gv_status_error ) THEN
      ov_retcode := gv_status_error;
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
  END chk_upload_data;
--
--
  /**********************************************************************************
   * Procedure Name   : insert_data
   * Description      : �f�[�^�o�^(A-6)
   ***********************************************************************************/
--
  PROCEDURE insert_data(
    in_file_id    IN  NUMBER,                                     -- FILE_ID
    iv_file_name  IN  xxccp_mrp_file_ul_interface.file_name%TYPE, -- �t�@�C����
    i_scdl_tab    IN  xm_schedule_if_ttype,                       -- ��v��f�[�^
    id_base_date  IN  DATE,                                       -- �m���
    on_normal_cnt OUT NUMBER,                                     -- ���팏��
    on_warn_cnt   OUT NUMBER,                                     -- �X�L�b�v����
    ov_errbuf     OUT VARCHAR2,                                   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,                                   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)                                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_data'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    ln_normal_cnt     NUMBER                                    ; -- ���팏��
    ln_warn_cnt       NUMBER                                    ; -- �X�L�b�v����
    -- *** ���[�J��RECORD�^ ***
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J��TABLE�^ ***
    -- *** ���[�J��PL/SQL�\ ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J����O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
  ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
  --1.���������̏�����
  ln_normal_cnt := 0;
  ln_warn_cnt   := 0;
  --
  --2.��v��o�^
  <<row_loop>>
  FOR ln_row_idx IN i_scdl_tab.FIRST .. i_scdl_tab.LAST LOOP
    --�X�L�b�v���� [�v����t �� �m���]
    IF i_scdl_tab(ln_row_idx).schedule_date <= id_base_date THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_xxcop
                     ,iv_name         => gv_m_n_skip_rec
                     ,iv_token_name1  => gv_t_row_num
                     ,iv_token_value1 => ln_row_idx
                     ,iv_token_name2  => gv_t_date1
                     ,iv_token_value2 => TO_CHAR(i_scdl_tab(ln_row_idx).schedule_date,gv_ymd_out_format)
                     ,iv_token_name3  => gv_t_date2
                     ,iv_token_value3 => TO_CHAR(id_base_date,gv_ymd_out_format)
                   );
      output_disp(
         iv_errmsg  => lv_errmsg
        ,iv_errbuf  => lv_errbuf
      );
      --
      --�X�L�b�v�����J�E���g
      ln_warn_cnt := ln_warn_cnt + 1;
    ELSE
      --���R�[�h�o�^
      INSERT
--20090403_Ver1.1_T1_0237_SCS.Goto_MOD_START
--      INTO   xxcop.xxcop_mrp_schedule_interface(      -- ��v��IF�\
      INTO   xxcop_mrp_schedule_interface(            -- ��v��IF�\
--20090403_Ver1.1_T1_0237_SCS.Goto_MOD_END
               --IF������
               transaction_id
              ,file_id
              ,file_name
              ,row_no
              --�w�b�_���
              ,schedule_designator
              ,schedule_description
              ,organization_code
              ,schedule_type
              --�i�ږ��׏��
              ,item_code
              --���t�ڍ׏��
              ,schedule_date
              ,schedule_quantity
              ,deliver_from
              ,shipment_date
              ,schedule_prod_flg
              --�ȉ�WHO�J����
              ,created_by
              ,creation_date
              ,last_updated_by
              ,last_update_date
              ,last_update_login
              ,request_id
              ,program_application_id
              ,program_id
              ,program_update_date
             )
      VALUES ( --IF������
--20090403_Ver1.1_T1_0237_SCS.Goto_MOD_START
--               XXCOP.XXCOP_MRP_SCHEDULE_IF_S1.NEXTVAL       -- ���ID�i���ݽ�j
               XXCOP_MRP_SCHEDULE_IF_S1.NEXTVAL             -- ���ID�i���ݽ�j
--20090403_Ver1.1_T1_0237_SCS.Goto_MOD_END
              ,in_file_id                                   -- �t�@�C��ID
              ,iv_file_name                                 -- �t�@�C����
              ,ln_row_idx                                   -- �sNo
               --�w�b�_���
              ,i_scdl_tab(ln_row_idx).schedule_designator   -- MDS/MPS��
              ,i_scdl_tab(ln_row_idx).schedule_description  -- MDS/MPS�E�v
              ,i_scdl_tab(ln_row_idx).organization_code     -- �g�D�R�[�h
              ,i_scdl_tab(ln_row_idx).schedule_type         -- ��v�敪��
               --�i�ږ��׏��
              ,i_scdl_tab(ln_row_idx).item_code             -- �i�ڃR�[�h
               --���t�ڍ׏��
              ,i_scdl_tab(ln_row_idx).schedule_date         -- �v����t
--20090403_Ver1.1_T1_0270_SCS.Goto_MOD_START
--              ,i_scdl_tab(ln_row_idx).schedule_quantity     -- �v�搔��
              ,i_scdl_tab(ln_row_idx).schedule_quantity
                * i_scdl_tab(ln_row_idx).num_of_cases       -- �v�搔��
--20090403_Ver1.1_T1_0270_SCS.Goto_MOD_END
              ,i_scdl_tab(ln_row_idx).deliver_from          -- �o�׌��q�ɃR�[�h
              ,i_scdl_tab(ln_row_idx).shipment_date         -- �o�ד�
              ,i_scdl_tab(ln_row_idx).schedule_prod_flg     -- �v�揤�i�t���O
               --�ȉ�WHO�J����
              ,gn_created_by                                -- CREATED_BY
              ,gd_creation_date                             -- CREATION_DATE
              ,gn_last_updated_by                           -- LAST_UPDATED_BY
              ,gd_last_update_date                          -- LAST_UPDATE_DATE
              ,gn_last_update_login                         -- LAST_UPDATE_LOGIN
              ,gn_request_id                                -- REQUEST_ID
              ,gn_program_application_id                    -- PROGRAM_APPLICATION_ID
              ,gn_program_id                                -- PROGRAM_ID
              ,gd_program_update_date                       -- PROGRAM_UPDATE_DATE
      );
      --
      --�o�^�G���[
      IF ( SQL%ROWCOUNT != 1 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_insert_err
                       ,iv_token_name1  => gv_t_table
                       ,iv_token_value1 => gv_table_name_ift
                     );
        RAISE global_process_expt;
      END IF;
      --
      --���폈�������J�E���g
      ln_normal_cnt := ln_normal_cnt + 1;
      --
    END IF;
    --
  END LOOP row_loop;
--
  on_normal_cnt := ln_normal_cnt;
  on_warn_cnt   := ln_warn_cnt;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
  END insert_data;
--
--
  /**********************************************************************************
   * Procedure Name   : delete_data
   * Description      : �t�@�C���A�b�v���[�hI/F�e�[�u���f�[�^�폜(A-7)
   ***********************************************************************************/
--
  PROCEDURE delete_data(
    in_file_id    IN  NUMBER,                              -- �t�@�C��ID
    ov_errbuf     OUT VARCHAR2,                            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,                            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_data'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J��RECORD�^ ***
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J��TABLE�^ ***
    -- *** ���[�J��PL/SQL�\ ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J����O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
  ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --1.�t�@�C���A�b�v���[�h�e�[�u���f�[�^�폜����
    xxcop_common_pkg.delete_upload_table(
       in_file_id   => in_file_id         -- �t�@�C��ID
      ,ov_retcode   => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errbuf    => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_errmsg    => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> gv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
  END delete_data;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE submain(
    in_file_id      IN  NUMBER,       --   FILE_ID
    iv_format       IN  VARCHAR2,     --   �t�H�[�}�b�g�p�^�[��
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
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
    cv_next_conc_application  CONSTANT VARCHAR2(100)  := 'XXCOP'       ; -- �㑱�����̃A�v���P�[�V������
    cv_next_conc_program      CONSTANT VARCHAR2(100)  := 'XXCOP001A02C'; -- �㑱�����̃v���O������
    cv_next_conc_name         CONSTANT VARCHAR2(100)  := '��v��̎捞'; -- �㑱�����̓��{�ꖼ
--
    -- *** ���[�J���ϐ� ***
    ld_base_date      DATE                                      ; -- �m���
    lv_file_name      xxccp_mrp_file_ul_interface.file_name%TYPE; -- �t�@�C����
    l_fuid_tab        xxccp_common_pkg2.g_file_data_tbl         ; -- �t�@�C���A�b�v���[�h�f�[�^(VARCHAR2)
    l_scdl_tab        xm_schedule_if_ttype                      ; -- ��v��\�f�[�^
    ln_normal_cnt     NUMBER                                    ; -- ���팏��
    ln_warn_cnt       NUMBER                                    ; -- �X�L�b�v����
    ln_request_id              NUMBER                           ; -- �v��ID�iA02�N�����j
    -- *** ���[�J��RECORD�^ ***
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    BEGIN
--
      --���������̏�����
      ln_normal_cnt := 0;
      --
      --*********************************************
      --*** �������F��������                        ***
      --*** ����NO�FA-1                            ***
      --*********************************************
      init(
         iv_format          --   �t�H�[�}�b�g�p�^�[��
        ,ld_base_date       --   �m���
        ,lv_errbuf          --   �G���[�E���b�Z�[�W          --# �Œ� #
        ,lv_retcode         --   ���^�[���E�R�[�h            --# �Œ� #
        ,lv_errmsg          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF ( lv_retcode = gv_status_error ) THEN
        --�f�o�b�O���O
        fnd_file.put_line(FND_FILE.LOG,'A-1:Process Error');
        RAISE global_process_expt;
      END IF;
      --�f�o�b�O���O
      fnd_file.put_line(FND_FILE.LOG,'A-1:Process Success');
--
      --*********************************************
      --*** �������F�֘A�f�[�^�擾                   ***
      --*** ����NO�FA-2                            ***
      --*********************************************
      get_file_info(
         in_file_id                   --   FILE_ID
        ,iv_format                    --   �t�H�[�}�b�g�p�^�[��
        ,lv_file_name                 --   �t�@�C����
        ,lv_errbuf                    --   �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                   --   ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg                    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF ( lv_retcode = gv_status_error ) THEN
        --�f�o�b�O���O
        fnd_file.put_line(FND_FILE.LOG,'A-2:Process Error');
        RAISE global_process_expt;
      END IF;
      --�f�o�b�O���O
      fnd_file.put_line(FND_FILE.LOG,'A-2:Process Success');
--
      --**************************************************
      --*** �������F�t�@�C���A�b�v���[�hI/F�e�[�u���f�[�^���o ***
      --*** ����NO�FA-3                                  ***
      --**************************************************
      get_upload_data(
        in_file_id            --   FILE_ID
       ,l_fuid_tab            --   �t�@�C���f�[�^
       ,lv_errbuf             --   �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode            --   ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg             --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF ( lv_retcode = gv_status_error ) THEN
        --�f�o�b�O���O
        fnd_file.put_line(FND_FILE.LOG,'A-3:Process Error');
        RAISE global_process_expt;
      END IF;
      --�f�o�b�O���O
      fnd_file.put_line(FND_FILE.LOG,'A-3:Process Success');
--
      --*********************************************
      --*** �������F�Ó����`�F�b�N                   ***
      --*** ����NO�FA-4                            ***
      --*********************************************
      chk_upload_data(
        iv_format             -- �t�H�[�}�b�g�p�^�[��
       ,l_fuid_tab            -- �t�@�C���f�[�^
       --����2009/01/23 �ǉ�
       ,ld_base_date          -- �m���
       --����2009/01/23 �ǉ�
       ,l_scdl_tab            -- ��v��f�[�^
       ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF ( lv_retcode = gv_status_error ) THEN
        --�f�o�b�O���O
        fnd_file.put_line(FND_FILE.LOG,'A-4:Process Error');
        RAISE global_process_expt;
      END IF;
      --�f�o�b�O���O
      fnd_file.put_line(FND_FILE.LOG,'A-4:Process Success');
--
      --*********************************************
      --*** �������F�f�[�^�o�^                      ***
      --*** ����NO�FA-6                            ***
      --*********************************************
      insert_data(
        in_file_id            -- �t�@�C��ID
       ,lv_file_name          -- �t�@�C����
       ,l_scdl_tab            -- ��v��f�[�^
       ,ld_base_date          -- �m���
       ,ln_normal_cnt         -- ���팏��
       ,ln_warn_cnt           -- �X�L�b�v����
       ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF ( lv_retcode = gv_status_error ) THEN
        --�f�o�b�O���O
        fnd_file.put_line(FND_FILE.LOG,'A-6:Process Error');
        RAISE global_process_expt;
      END IF;
      --
      --�f�o�b�O���O
      fnd_file.put_line(FND_FILE.LOG,'A-6:Process Success');
--
    -- =======================================================================
    -- ��[A-1]?[A-6]�Ŕ��������G���[���W�񂵃��[���o�b�N�����s�B�㑱�̃f�[�^�폜�����ցB
    -- =======================================================================
    EXCEPTION
      WHEN global_process_expt THEN
        lv_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
        ov_retcode := gv_status_error;
      WHEN OTHERS THEN
        --�G���[���b�Z�[�W���o��
        lv_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
        ov_retcode := gv_status_error;
    END;
    --
    --�I���X�e�[�^�X���G���[�̏ꍇ�A���[���o�b�N����B
    IF ( ov_retcode <> gv_status_normal ) THEN
      ROLLBACK;
      --�G���[���b�Z�[�W���o��
      output_disp(
         iv_errmsg  => lv_errmsg
        ,iv_errbuf  => lv_errbuf
      );
    END IF;
--
    --***************************************************
    --*** �������F�t�@�C���A�b�v���[�hI/F�e�[�u���f�[�^�폜  ***
    --*** ����NO�FA-7                                   ***
    --***************************************************
    delete_data(
      in_file_id            -- �t�@�C��ID
     ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,Lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = gv_status_normal ) THEN
      --�f�o�b�O���O
      fnd_file.put_line(FND_FILE.LOG,'A-7:Process Success');
      --
      IF ( ov_retcode <> gv_status_normal ) THEN
        --�G���[�̏ꍇ�ł��A�t�@�C���A�b�v���[�hI/F�e�[�u���̍폜�����������ꍇ�̓R�~�b�g����B
        COMMIT;
      END IF;
    ELSE
      --�f�o�b�O���O
      fnd_file.put_line(FND_FILE.LOG,'A-7:Process Error');
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    END IF;
    --
    IF ( ov_retcode = gv_status_normal ) THEN
      --�I���X�e�[�^�X������̏ꍇ�A�����������Z�b�g����B
      gn_normal_cnt := ln_normal_cnt;
      --���ȉ��m�F�����X�L�b�v�������ɃX�e�[�^�X�𐳏�Ƃ��邩�x���Ƃ��邩�ŏ����̏ꏊ���ς��
      gn_warn_cnt   := ln_warn_cnt;
    ELSE
      --�I���X�e�[�^�X���G���[�̏ꍇ�A�G���[�������Z�b�g����B
      IF ( gn_error_cnt = 0 ) THEN
        gn_error_cnt := 1;
      END IF;
    END IF;
--
    -- ===============================
    -- ��2009/01/15 �ǉ�
    -- �R���J�����g[XXCOP001A02C]�N������
    -- ===============================
    IF ( ov_retcode <> gv_status_error ) THEN
      --�R���J�����g[XXCOP001A02C]�N��
      ln_request_id := fnd_request.submit_request(
                          application  => cv_next_conc_application
                         ,program      => cv_next_conc_program
                         ,argument1    => in_file_id
                         ,argument2    => iv_format
                       );
--
      --�G���[���b�Z�[�W�o��
      IF ( ln_request_id = 0 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_xxcop
                       ,iv_name         => gv_m_e_conc_call
                       ,iv_token_name1  => gv_t_syori
                       ,iv_token_value1 => cv_next_conc_name
                     );
        --�f�o�b�O���O
        fnd_file.put_line(FND_FILE.LOG,SQLERRM);
        --
        RAISE global_api_expt;
      END IF;
--
      --�R���J�����g[XXCOP001A02C]�N���̂��߃R�~�b�g
      COMMIT;
--
    END IF;
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
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
--  
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    in_file_id    IN     NUMBER,           --   FILE_ID
    iv_format     IN     VARCHAR2          --   �t�H�[�}�b�g�p�^�[��
  )
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; --����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; --�x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; --�װ�I�����b�Z�[�W�i�S�������O�߂��j
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf            VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code      VARCHAR2(100);
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_h_plan_file_name  VARCHAR2(1000);  -- ����v��t�@�C����
--
  BEGIN
--
  --[retcode]�������i�L�q���[�����j
  retcode := gv_status_normal;
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
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    --�s��
    fnd_file.put_line(FND_FILE.OUTPUT,'');
    --
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       in_file_id           -- FILE_ID
      ,iv_format            -- �t�H�[�}�b�g�p�^�[��
      ,lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
--
    -- ===============================
    -- �G���[���b�Z�[�W�o�͏���
    -- ===============================
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errbuf --�G���[���b�Z�[�W
    );
    --
    --�s��
    fnd_file.put_line(FND_FILE.OUTPUT,'');
    --
    -- ===============================
    -- �Ώی����o�͏���
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- ===============================
    -- ���������o�͏���
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- ===============================
    -- �G���[�����o�͏���
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- ===============================
    -- �X�L�b�v�����o��
    -- ===============================
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
    --�s��
    fnd_file.put_line(FND_FILE.OUTPUT,'');
    --
    -- ===============================
    -- �I�����b�Z�[�W�o��
    -- ===============================
    IF ( retcode = gv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = gv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( retcode = gv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- ===============================
    -- �G���[�����iROLLBACK�j
    -- ===============================
    IF ( retcode = gv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
      ROLLBACK;
  END main;
--
END XXCOP001A01C;
/
