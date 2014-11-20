CREATE OR REPLACE PACKAGE BODY xxwsh920006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh920006c(body)
 * Description      : �q�ɕi�ڃ}�X�^�捞����
 * MD.050           : ���Y�������ʁi�o�ׁE�ړ��������jT_MD050_BPO_922
 * MD.070           : �q�ɕi�ڃ}�X�^�捞����(92H) T_MD070_BPO_92H
 * Version          : 1.0
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                       Description
 * --------------------------- ----------------------------------------------------------
 *  init_proc                   �֘A�f�[�^�擾����(H-1)
 *  get_request_id              �v��ID�擾����(H-2)
 *  get_lock                    ���b�N�擾����(H-3)
 *  del_duplication_data        �d���f�[�^���O����(H-4)
 *  ins_data_loop               �o�^�f�[�^�擾����(H-5)
 *  upd_data_loop               �X�V�f�[�^�擾����(H-6)
 *  chk_master_data             �}�X�^�f�[�^�`�F�b�N����(H-7)
 *  chk_consistency_data        �Ó����`�F�b�N����(H-8)
 *  set_ins_tab                 �o�^�pPL/SQL�\����(H-9)
 *  set_upd_tab                 �X�V�pPL/SQL�\����(H-10)
 *  ins_table_batch             �ꊇ�o�^����(H-11)
 *  upd_table_batch             �ꊇ�X�V����(H-12)
 *  del_data                    �ꊇ�폜����(H-13)
 *  put_dump_msg                �f�[�^�_���v�ꊇ�o�͏���(H-14)
 *  submain                     ���C�������v���V�[�W��
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/06/12    1.0   H.Itou           �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  gv_msg_comma     CONSTANT VARCHAR2(3) := ',';
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
  -- ���[�U�[��`��O
  -- ===============================
  lock_expt              EXCEPTION;        -- ���b�N�擾��O
  skip_expt              EXCEPTION;        -- �X�L�b�v��O
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxwsh920006c'; -- �p�b�P�[�W��
  -- ���W���[��������
  gv_xxcmn           CONSTANT VARCHAR2(100) := 'XXCMN';        -- ���W���[�������́FXXCMN
  gv_xxwsh           CONSTANT VARCHAR2(100) := 'XXWSH';        -- ���W���[�������́FXXWSH
--
  -- ���b�Z�[�W
  gv_msg_xxcmn10002  CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002'; -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
  gv_msg_xxcmn10019  CONSTANT VARCHAR2(100) := 'APP-XXCMN-10019'; -- ���b�Z�[�W�FAPP-XXCMN-10019 ���b�N�G���[
  gv_msg_xxcmn10001  CONSTANT VARCHAR2(100) := 'APP-XXCMN-10001'; -- ���b�Z�[�W�FAPP-XXCMN-10001 �Ώۃf�[�^�Ȃ�
  gv_msg_xxcmn00005  CONSTANT VARCHAR2(100) := 'APP-XXCMN-00005'; -- ���b�Z�[�W�FAPP-XXCMN-00005 �����f�[�^�i���o���j
  gv_msg_xxcmn00007  CONSTANT VARCHAR2(100) := 'APP-XXCMN-00007'; -- ���b�Z�[�W�FAPP-XXCMN-00007 �X�L�b�v�f�[�^�i���o���j
  gv_msg_xxwsh13451  CONSTANT VARCHAR2(100) := 'APP-XXWSH-13451'; -- ���b�Z�[�W�FAPP-XXWSH-13451 �f�[�^�d���G���[���b�Z�[�W
  gv_msg_xxwsh13452  CONSTANT VARCHAR2(100) := 'APP-XXWSH-13452'; -- ���b�Z�[�W�FAPP-XXWSH-13452 ���q�ɃG���[
  gv_msg_xxwsh13453  CONSTANT VARCHAR2(100) := 'APP-XXWSH-13453'; -- ���b�Z�[�W�FAPP-XXWSH-13453 ��\�q�ɃG���[
--
  -- �g�[�N��
  gv_tkn_value              CONSTANT VARCHAR2(100) := 'VALUE';            -- �g�[�N���FVALUE
  gv_tkn_item               CONSTANT VARCHAR2(100) := 'ITEM';             -- �g�[�N���FITEM
  gv_tkn_table              CONSTANT VARCHAR2(100) := 'TABLE';            -- �g�[�N���FTABLE
  gv_tkn_key                CONSTANT VARCHAR2(100) := 'KEY';              -- �g�[�N���FKEY
  gv_tkn_ng_profile         CONSTANT VARCHAR2(100) := 'NG_PROFILE';       -- �g�[�N���FNG_PROFILE
--
  -- �g�[�N������
  gv_xxwsh_frq_item_locations    CONSTANT VARCHAR2(50) := '�q�ɕi�ڃA�h�I���}�X�^';
  gv_xxwsh_frq_item_locations_if CONSTANT VARCHAR2(50) := '�q�ɕi�ڃA�h�I���}�X�^�C���^�t�F�[�X';
  gv_tkn_dummy_frequent_whse     CONSTANT VARCHAR2(100) := 'XXCMN:�_�~�[��\�q��';
  gv_tkn_item_locations          CONSTANT VARCHAR2(100) := 'OPM�ۊǏꏊ���';
  gv_tkn_item_mst                CONSTANT VARCHAR2(100) := 'OPM�i�ڏ��';
  gv_tkn_item_location_code      CONSTANT VARCHAR2(100) := '�ۊǏꏊ�R�[�h:';
  gv_tkn_item_code               CONSTANT VARCHAR2(100) := '�i�ڃR�[�h:';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �v��ID�pPL/SQL�\�^
  TYPE request_id_ttype         IS TABLE OF  fnd_concurrent_requests.request_id           %TYPE INDEX BY BINARY_INTEGER;  -- �v��ID
--
  -- ���b�Z�[�WPL/SQL�\�^
  TYPE msg_ttype                IS TABLE OF VARCHAR2(5000)                                      INDEX BY BINARY_INTEGER;
--
  -- �o�^�E�X�V�pPL/SQL�\�^
  TYPE pk_id_ttype              IS TABLE OF  xxwsh_frq_item_locations.pk_id               %TYPE INDEX BY BINARY_INTEGER;  -- �q�ɕi��ID
  TYPE item_location_id_ttype   IS TABLE OF  xxcmn_item_locations_v.inventory_location_id %TYPE INDEX BY BINARY_INTEGER;  -- �ۊǑq��ID
  TYPE item_location_code_ttype IS TABLE OF  xxcmn_item_locations_v.segment1              %TYPE INDEX BY BINARY_INTEGER;  -- �ۊǑq�ɃR�[�h
  TYPE item_id_ttype            IS TABLE OF  xxcmn_item_mst_v.item_id                     %TYPE INDEX BY BINARY_INTEGER;  -- �i��ID
  TYPE item_code_ttype          IS TABLE OF  xxcmn_item_mst_v.item_no                     %TYPE INDEX BY BINARY_INTEGER;  -- �i�ڃR�[�h
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �v��ID�pPL/SQL�\
  request_id_tab   request_id_ttype;
--
  -- �x���f�[�^�_���vPL/SQL�\
  warn_dump_tab    msg_ttype;
--
  -- ����f�[�^�_���vPL/SQL�\
  normal_dump_tab  msg_ttype; 
--
  -- �o�^�pPL/SQL�\
  pk_id_tab                       pk_id_ttype;                -- �q�ɕi��ID
  item_location_id_ins_tab        item_location_id_ttype;     -- ���q��ID
  item_location_code_ins_tab      item_location_code_ttype;   -- ���q�ɃR�[�h
  item_id_ins_tab                 item_id_ttype;              -- �i��ID
  item_code_ins_tab               item_code_ttype;            -- �i�ڃR�[�h
  frq_item_location_id_ins_tab    item_location_id_ttype;     -- ��\�q��ID
  frq_item_location_code_ins_tab  item_location_code_ttype;   -- ��\�q�ɃR�[�h
--
  -- �X�V�pPL/SQL�\
  frq_item_location_id_upd_tab    item_location_id_ttype;     -- ��\�q��ID
  item_location_code_upd_tab      item_location_code_ttype;   -- ���q�ɃR�[�h
  item_code_upd_tab               item_code_ttype;            -- �i�ڃR�[�h
  frq_item_location_code_upd_tab  item_location_code_ttype;   -- ��\�q��
--
  -- �J�E���g
  gn_request_id_cnt   NUMBER := 0;   -- �v��ID�J�E���g
  gn_warn_msg_cnt     NUMBER := 0;   -- �x���G���[���b�Z�[�W�\�J�E���g
  gn_ins_tab_cnt      NUMBER := 0;   -- �o�^�pPL/SQL�\�J�E���g
  gn_upd_tab_cnt      NUMBER := 0;   -- �X�V�pPL/SQL�\�J�E���g
--
  -- �v���t�@�C���I�v�V����
  gv_dummy_frequent_whse    VARCHAR2(100);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
    -- �q�ɕi�ڃA�h�I���}�X�^�C���^�t�F�[�X�o�^�J�[�\��
    CURSOR ins_cur(lt_request_id    xxwsh_frq_item_locations_if.request_id%TYPE)
    IS
      SELECT xfili.item_location_code      item_location_code       -- ���q�ɃR�[�h
            ,xilv1.inventory_location_id   item_location_id         -- ���q��ID
            ,xilv1.frequent_whse           frequent_whse            -- ���q��_��\�q��
            ,xfili.frq_item_location_code  frq_item_location_code   -- ��\�q�ɃR�[�h
            ,xilv2.inventory_location_id   frq_item_location_id     -- ��\�q��ID
            ,xilv2.frequent_whse           frq_frequent_whse        -- ��\�q��_��\�q��
            ,xfili.item_code               item_code                -- �i�ڃR�[�h
            ,ximv.item_id                  item_id                  -- �i��ID
            ,xfili.item_location_code     || gv_msg_comma ||
             xfili.item_code              || gv_msg_comma ||
             xfili.frq_item_location_code  data_dump                -- �f�[�^�_���v
      FROM   xxwsh_frq_item_locations_if   xfili                    -- �q�ɕi�ڃA�h�I���}�X�^�C���^�t�F�[�X
            ,xxcmn_item_locations_v        xilv1                    -- OPM�ۊǏꏊ���VIEW(���q�ɏ��)
            ,xxcmn_item_locations_v        xilv2                    -- OPM�ۊǏꏊ���VIEW(��\�q�ɏ��)
            ,xxcmn_item_mst_v              ximv                     -- OPM�i�ڏ��VIEW(�i�ڏ��)
      WHERE  -- ** �������� ���q�ɏ�� ** --
             xfili.item_location_code     = xilv1.segment1(+)
             -- ** �������� ��\�q�ɏ�� ** --
      AND    xfili.frq_item_location_code = xilv2.segment1(+)
             -- ** �������� �i�ڏ�� ** --
      AND    xfili.item_code              = ximv.item_no(+)
             -- ** ���o���� ** --
      AND    xfili.request_id             = lt_request_id           -- �v��ID
      AND    NOT EXISTS( -- �q�ɕi�ڃA�h�I���}�X�^�ɑ��݂��Ȃ��L�[���ڂ����f�[�^
                   SELECT 1
                   FROM   xxwsh_frq_item_locations  xfil                      -- �q�ɕi�ڃA�h�I���}�X�^
                   WHERE  xfil.item_location_code = xfili.item_location_code  -- ���q��
                   AND    xfil.item_code          = xfili.item_code           -- �i�ڃR�[�h
                 )
      ;
--
    -- �q�ɕi�ڃA�h�I���}�X�^�C���^�t�F�[�X�X�V�J�[�\��
    CURSOR upd_cur(lt_request_id    xxwsh_frq_item_locations_if.request_id%TYPE)
    IS
      SELECT xfili.item_location_code      item_location_code       -- ���q�ɃR�[�h
            ,xilv1.inventory_location_id   item_location_id         -- ���q��ID
            ,xilv1.frequent_whse           frequent_whse            -- ���q��_��\�q��
            ,xfili.frq_item_location_code  frq_item_location_code   -- ��\�q�ɃR�[�h
            ,xilv2.inventory_location_id   frq_item_location_id     -- ��\�q��ID
            ,xilv2.frequent_whse           frq_frequent_whse        -- ��\�q��_��\�q��
            ,xfili.item_code               item_code                -- �i�ڃR�[�h
            ,ximv.item_id                  item_id                  -- �i��ID
            ,xfili.item_location_code     || gv_msg_comma ||
             xfili.item_code              || gv_msg_comma ||
             xfili.frq_item_location_code  data_dump                -- �f�[�^�_���v
      FROM   xxwsh_frq_item_locations_if   xfili                    -- �q�ɕi�ڃA�h�I���}�X�^�C���^�t�F�[�X
            ,xxcmn_item_locations_v        xilv1                    -- OPM�ۊǏꏊ���VIEW(���q�ɏ��)
            ,xxcmn_item_locations_v        xilv2                    -- OPM�ۊǏꏊ���VIEW(��\�q�ɏ��)
            ,xxcmn_item_mst_v              ximv                     -- OPM�i�ڏ��VIEW(�i�ڏ��)
      WHERE  -- ** �������� ���q�ɏ�� ** --
             xfili.item_location_code     = xilv1.segment1(+)
             -- ** �������� ��\�q�ɏ�� ** --
      AND    xfili.frq_item_location_code = xilv2.segment1(+)
             -- ** �������� �i�ڏ�� ** --
      AND    xfili.item_code              = ximv.item_no(+)
             -- ** ���o���� ** --
      AND    xfili.request_id             = lt_request_id           -- �v��ID
      AND    EXISTS( -- �q�ɕi�ڃA�h�I���}�X�^�ɑ��݂���L�[���ڂ����f�[�^
               SELECT 1
               FROM   xxwsh_frq_item_locations  xfil                      -- �q�ɕi�ڃA�h�I���}�X�^
               WHERE  xfil.item_location_code = xfili.item_location_code  -- ���q��
               AND    xfil.item_code          = xfili.item_code           -- �i�ڃR�[�h
             )
      ;
--
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : �֘A�f�[�^�擾����(H-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_proc'; -- �v���O������
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
    cv_dummy_frequent_whse   VARCHAR2(100) := 'XXCMN_DUMMY_FREQUENT_WHSE';   -- �_�~�[��\�q��
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===========================
    -- �v���t�@�C���I�v�V�����擾
    -- ===========================
    gv_dummy_frequent_whse   := FND_PROFILE.VALUE(cv_dummy_frequent_whse);   -- �_�~�[��\�q��
--
    -- =========================================
    -- �v���t�@�C���I�v�V�����擾�G���[�`�F�b�N
    -- =========================================
    IF (gv_dummy_frequent_whse IS NULL) THEN -- �_�~�[��\�q�Ƀv���t�@�C���擾�G���[
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                     -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10002            -- ���b�Z�[�W:APP-XXCMN-10002 �v���t�@�C���擾�G���[
                       ,gv_tkn_ng_profile            -- �g�[�N��:NG�v���t�@�C����
                       ,gv_tkn_dummy_frequent_whse)  -- �_�~�[��\�q��
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
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
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_request_id
   * Description      : �v��ID�擾����(H-2)
   ***********************************************************************************/
  PROCEDURE get_request_id(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_request_id'; -- �v���O������
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
    -- �v��ID�J�[�\��
    CURSOR xfili_request_id_cur
    IS
      SELECT fcr.request_id request_id
      FROM   fnd_concurrent_requests fcr   -- �R���J�����g�v��ID�e�[�u��
      WHERE  EXISTS (
               SELECT 1
               FROM   xxwsh_frq_item_locations_if xfili   -- �q�ɕi�ڃA�h�I���}�X�^�C���^�t�F�[�X
               WHERE  xfili.request_id = fcr.request_id   -- �v��ID
               AND    ROWNUM          = 1
             )
      ORDER BY request_id
    ;
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    <<get_request_id_loop>>
    FOR lr_xfili_request_id IN xfili_request_id_cur
    LOOP
      gn_request_id_cnt := gn_request_id_cnt + 1 ;
      request_id_tab(gn_request_id_cnt) := lr_xfili_request_id.request_id;
    END LOOP get_request_id_loop;
--
  EXCEPTION
--
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
  END get_request_id;
--
  /**********************************************************************************
   * Procedure Name   : get_lock
   * Description      : ���b�N�擾����(H-3)
   ***********************************************************************************/
  PROCEDURE get_lock(
    ov_errbuf     OUT VARCHAR2,         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,         --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lock'; -- �v���O������
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
    -- �q�ɕi�ڃA�h�I���}�X�^�C���^�t�F�[�X�J�[�\��
    CURSOR if_lock_cur(lt_request_id xxwsh_frq_item_locations_if.request_id%TYPE)
    IS
      SELECT xfili.seq_number  seq_number
      FROM   xxwsh_frq_item_locations_if    xfili -- �q�ɕi�ڃA�h�I���}�X�^�C���^�t�F�[�X
      WHERE  xfili.request_id = lt_request_id     -- �v��ID
      FOR UPDATE NOWAIT
    ;
--
    -- �q�ɕi�ڃA�h�I���}�X�^�J�[�\��
    CURSOR lock_cur
    IS
      SELECT xfil.pk_id  pk_id
      FROM   xxwsh_frq_item_locations   xfil     -- �q�ɕi�ڃA�h�I���}�X�^
      FOR UPDATE NOWAIT
    ;
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==================================================
    -- �q�ɕi�ڃA�h�I���}�X�^�C���^�t�F�[�X ���b�N�擾
    -- ==================================================
    BEGIN
      <<request_id_loop>>
      FOR ln_count IN 1..request_id_tab.COUNT
      LOOP
        <<if_lock_loop>>
        FOR lr_if_lock IN if_lock_cur(request_id_tab(ln_count))
        LOOP
          EXIT;
        END LOOP look_if_loop;
      END LOOP request_id_loop;
--
    EXCEPTION
      WHEN lock_expt THEN --*** ���b�N�擾�G���[ ***
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxcmn                        -- ���W���[�������́FXCMN
                         ,gv_msg_xxcmn10019               -- ���b�Z�[�W�FAPP-XXCMN-10019 ���b�N�G���[
                         ,gv_tkn_table                    -- �g�[�N��TABLE
                         ,gv_xxwsh_frq_item_locations_if) -- �e�[�u�����F�q�ɕi�ڃA�h�I���}�X�^�C���^�t�F�[�X
                       ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- =====================================
    -- �q�ɕi�ڃA�h�I���}�X�^ ���b�N�擾
    -- =====================================
    BEGIN
       <<lock_loop>>
      FOR lr_lock IN lock_cur
      LOOP
        EXIT;
      END LOOP lock_loop;
--
    EXCEPTION
      WHEN lock_expt THEN --*** ���b�N�擾�G���[ ***
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxcmn                        -- ���W���[�������́FXCMN
                         ,gv_msg_xxcmn10019               -- ���b�Z�[�W�FAPP-XXCMN-10019 ���b�N�G���[
                         ,gv_tkn_table                    -- �g�[�N��TABLE
                         ,gv_xxwsh_frq_item_locations)    -- �e�[�u�����F�q�ɕi�ڃA�h�I���}�X�^
                       ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
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
  END get_lock;
--
--
  /**********************************************************************************
   * Procedure Name   : del_duplication_data
   * Description      : �d���f�[�^���O����(H-4)
   ***********************************************************************************/
  PROCEDURE del_duplication_data(
    it_request_id IN  xxwsh_frq_item_locations_if.request_id%TYPE,     -- 1.�v��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_duplication_data'; -- �v���O������
    cv_item       CONSTANT VARCHAR2(100) := '�f�[�^';
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
    -- �d���`�F�b�N�J�[�\��
    CURSOR duplication_chk_cur
    IS
      SELECT xfili2.cnt                     cnt                      -- �J�E���g
            ,xfili1.item_location_code      item_location_code       -- ���q��
            ,xfili1.item_code               item_code                -- �i�ڃR�[�h
            ,xfili1.request_id              request_id               -- �v��ID
            ,xfili1.item_location_code     || gv_msg_comma ||
             xfili1.item_code              || gv_msg_comma ||
             xfili1.frq_item_location_code  data_dump                -- �f�[�^�_���v
      FROM   xxwsh_frq_item_locations_if    xfili1                   -- �q�ɕi�ڃA�h�I���}�X�^�C���^�t�F�[�X
            ,(SELECT COUNT(xfili.seq_number)      cnt                -- �J�E���g
                    ,xfili.item_location_code     item_location_code -- ���q��
                    ,xfili.item_code              item_code          -- �i�ڃR�[�h
                    ,xfili.request_id             request_id         -- �v��ID
              FROM   xxwsh_frq_item_locations_if  xfili              -- �q�ɕi�ڃA�h�I���}�X�^�C���^�t�F�[�X
              GROUP BY 
                     xfili.item_location_code                        -- ���q��
                    ,xfili.item_code                                 -- �i�ڃR�[�h
                    ,xfili.request_id                                -- �v��ID
             )                            xfili2                     -- �d���J�E���g�p���⍇��
      WHERE -- ** �������� ** --
            xfili1.item_location_code = xfili2.item_location_code    -- ���q��
      AND   xfili1.item_code          = xfili2.item_code             -- �i�ڃR�[�h
      AND   xfili1.request_id         = xfili2.request_id            -- �v��ID
            -- ** ���o���� ** --
      AND   xfili1.request_id         = it_request_id                -- �v��ID
      AND   xfili2.cnt                > 1                            -- ����L�[��2���ȏ�
    ;
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �d���`�F�b�N
    -- ===============================
    <<duplication_chk_loop>>
    FOR lr_duplication_chk IN duplication_chk_cur LOOP
      -- �d���x�����b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxwsh               -- ���W���[�������́FXXWSH
                       ,gv_msg_xxwsh13451)     -- ���b�Z�[�W�FAPP-XXWSH-13451 �f�[�^�d���G���[���b�Z�[�W
                     ,1,5000);
--
      -- �x���_���vPL/SQL�\�Ƀ_���v���Z�b�g
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lr_duplication_chk.data_dump;
--
      -- �x���_���vPL/SQL�\�Ɍx�����b�Z�[�W���Z�b�g
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      --  ���^�[���E�R�[�h�Ɍx�����Z�b�g
      ov_retcode := gv_status_warn;
--
      -- �X�L�b�v�����J�E���g
      gn_warn_cnt   := gn_warn_cnt + 1;
--
      -- ===============================
      -- �G���[�f�[�^�폜
      -- ===============================
      DELETE xxwsh_frq_item_locations_if xfili   -- �q�ɕi�ڃA�h�I���}�X�^�C���^�t�F�[�X
      WHERE  xfili.item_location_code = lr_duplication_chk.item_location_code       -- ���q��
      AND    xfili.item_code          = lr_duplication_chk.item_code                -- �i�ڃR�[�h
      AND    xfili.request_id         = lr_duplication_chk.request_id               -- �v��ID
      ;
--
    END LOOP duplication_chk_loop;
--
  EXCEPTION
--
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
  END del_duplication_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_master_data
   * Description      : �}�X�^�f�[�^�`�F�b�N����(H-7)
   ***********************************************************************************/
  PROCEDURE chk_master_data(
    ir_chk_data   IN  ins_cur%ROWTYPE, -- �`�F�b�N�f�[�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_master_data'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    ln_cnt NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
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
    -- ===========================
    -- ���q�Ƀ`�F�b�N
    -- ===========================
    -- ���q��ID�𒊏o�ł��Ă��Ȃ��ꍇ�A�x��
    IF (ir_chk_data.item_location_id IS NULL) THEN
      -- �x�����b�Z�[�W�o��
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn               -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10001      -- ���b�Z�[�W:APP-XXCMN-10001 �Ώۃf�[�^�Ȃ�
                       ,gv_tkn_table           -- �g�[�N��:TABLE
                       ,gv_tkn_item_locations  -- �G���[�e�[�u����
                       ,gv_tkn_key             -- �g�[�N��:KEY
                       ,gv_tkn_item_location_code || ir_chk_data.item_location_code)  -- �G���[�L�[����
                     ,1,5000);
--
      -- �x���_���vPL/SQL�\�Ƀ_���v���Z�b�g
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := ir_chk_data.data_dump;
--
      -- �x���_���vPL/SQL�\�Ɍx�����b�Z�[�W���Z�b�g
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- ���^�[���E�R�[�h�Ɍx�����Z�b�g
      ov_retcode := gv_status_warn;
--
    END IF;
--
    -- ===========================
    -- ��\�q�Ƀ`�F�b�N
    -- ===========================
    -- ��\�q��ID�𒊏o�ł��Ă��Ȃ��ꍇ�A�x��
    IF (ir_chk_data.frq_item_location_id IS NULL) THEN
      -- �x�����b�Z�[�W�o��
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn               -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10001      -- ���b�Z�[�W:APP-XXCMN-10001 �Ώۃf�[�^�Ȃ�
                       ,gv_tkn_table           -- �g�[�N��:TABLE
                       ,gv_tkn_item_locations  -- �G���[�e�[�u����
                       ,gv_tkn_key             -- �g�[�N��:KEY
                       ,gv_tkn_item_location_code || ir_chk_data.frq_item_location_code)  -- �G���[�L�[����
                     ,1,5000);
--
      -- ���łɌx���̏ꍇ�́A�_���v�s�v
      IF (ov_retcode <> gv_status_warn) THEN
        -- �x���_���vPL/SQL�\�Ƀ_���v���Z�b�g
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := ir_chk_data.data_dump;
      END IF;
--
      -- �x���_���vPL/SQL�\�Ɍx�����b�Z�[�W���Z�b�g
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- ���^�[���E�R�[�h�Ɍx�����Z�b�g
      ov_retcode := gv_status_warn;
--
    END IF;
--
    -- ===========================
    -- �i�ڃR�[�h�`�F�b�N
    -- ===========================
    -- �i��ID�𒊏o�ł��Ă��Ȃ��ꍇ�A�x��
    IF (ir_chk_data.item_id IS NULL) THEN
      -- �x�����b�Z�[�W�o��
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn               -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10001      -- ���b�Z�[�W:APP-XXCMN-10001 �Ώۃf�[�^�Ȃ�
                       ,gv_tkn_table           -- �g�[�N��:TABLE
                       ,gv_tkn_item_mst        -- �G���[�e�[�u����
                       ,gv_tkn_key             -- �g�[�N��:KEY
                       ,gv_tkn_item_code || ir_chk_data.item_code)  -- �G���[�L�[����
                     ,1,5000);
--
      -- ���łɌx���̏ꍇ�́A�_���v�s�v
      IF (ov_retcode <> gv_status_warn) THEN
        -- �x���_���vPL/SQL�\�Ƀ_���v���Z�b�g
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := ir_chk_data.data_dump;
      END IF;
--
      -- �x���_���vPL/SQL�\�Ɍx�����b�Z�[�W���Z�b�g
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- ���^�[���E�R�[�h�Ɍx�����Z�b�g
      ov_retcode := gv_status_warn;
--
    END IF;
  EXCEPTION
--
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
  END chk_master_data;
--
--
  /**********************************************************************************
   * Procedure Name   : chk_consistency_data
   * Description      : �Ó����`�F�b�N����(H-8)
   ***********************************************************************************/
  PROCEDURE chk_consistency_data(
    ir_chk_data   IN  ins_cur%ROWTYPE, -- �`�F�b�N�f�[�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_consistency_data'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
    ln_cnt NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
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
    -- ===========================
    -- ���q�ɑÓ����`�F�b�N
    -- ===========================
    -- ���q��_��\�q�ɂ��_�~�[��\�q�ɂłȂ��ꍇ�A�x��
    IF (ir_chk_data.frequent_whse <> gv_dummy_frequent_whse) THEN
      -- �x�����b�Z�[�W�o��
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxwsh               -- ���W���[��������:XWSH
                       ,gv_msg_xxwsh13452)     -- ���b�Z�[�W:APP-XXWSH-13452 ���q�ɃG���[
                     ,1,5000);
--
      -- �x���_���vPL/SQL�\�Ƀ_���v���Z�b�g
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := ir_chk_data.data_dump;
--
      -- �x���_���vPL/SQL�\�Ɍx�����b�Z�[�W���Z�b�g
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- ���^�[���E�R�[�h�Ɍx�����Z�b�g
      ov_retcode := gv_status_warn;
--
    END IF;
--
    -- ===========================
    -- ��\�q�ɑÓ����`�F�b�N
    -- ===========================
    -- ��\�q�ɂ���\�q��_��\�q�ɂłȂ��ꍇ�A�x��
    IF (ir_chk_data.frq_item_location_code <> ir_chk_data.frq_frequent_whse) THEN
--
      -- �x�����b�Z�[�W�o��
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxwsh               -- ���W���[��������:XWSH
                       ,gv_msg_xxwsh13453)     -- ���b�Z�[�W:APP-XXWSH-13453 ��\�q�ɃG���[
                     ,1,5000);
--
      -- ���łɌx���̏ꍇ�́A�_���v�s�v
      IF (ov_retcode <> gv_status_warn) THEN
        -- �x���_���vPL/SQL�\�Ƀ_���v���Z�b�g
        gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
        warn_dump_tab(gn_warn_msg_cnt) := ir_chk_data.data_dump;
      END IF;
--
      -- �x���_���vPL/SQL�\�Ɍx�����b�Z�[�W���Z�b�g
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
      -- ���^�[���E�R�[�h�Ɍx�����Z�b�g
      ov_retcode := gv_status_warn;
--
    END IF;
--
  EXCEPTION
--
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
  END chk_consistency_data;
--
  /**********************************************************************************
   * Procedure Name   : set_ins_tab
   * Description      : �o�^�pPL/SQL�\����(H-9)
   ***********************************************************************************/
  PROCEDURE set_ins_tab(
    ir_data       IN  ins_cur%ROWTYPE, -- �f�[�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_ins_tab'; -- �v���O������
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �o�^�pPL/SQL�\�ɃZ�b�g
    -- ===============================
    -- �o�^�p�����J�E���g
    gn_ins_tab_cnt := gn_ins_tab_cnt + 1;
--
    SELECT xxwsh_frq_item_locations_id_s1.NEXTVAL
    INTO   pk_id_tab(gn_ins_tab_cnt)                                   -- �q�ɕi��ID
    FROM   DUAL;
    item_location_id_ins_tab(gn_ins_tab_cnt)       := ir_data.item_location_id;       -- ���q��ID
    item_location_code_ins_tab(gn_ins_tab_cnt)     := ir_data.item_location_code;     -- ���q�ɃR�[�h
    item_id_ins_tab(gn_ins_tab_cnt)                := ir_data.item_id;                -- �i��ID
    item_code_ins_tab(gn_ins_tab_cnt)              := ir_data.item_code;              -- �i�ڃR�[�h
    frq_item_location_id_ins_tab(gn_ins_tab_cnt)   := ir_data.frq_item_location_id;   -- ��\�q��ID
    frq_item_location_code_ins_tab(gn_ins_tab_cnt) := ir_data.frq_item_location_code; -- ��\�q�ɃR�[�h
--
  EXCEPTION
--
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
  END set_ins_tab;
--
  /**********************************************************************************
   * Procedure Name   : set_upd_tab
   * Description      : �X�V�pPL/SQL�\����(H-10)
   ***********************************************************************************/
  PROCEDURE set_upd_tab(
    ir_data       IN  ins_cur%ROWTYPE, -- �f�[�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_upd_tab'; -- �v���O������
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �X�V�pPL/SQL�\�ɃZ�b�g
    -- ===============================
    -- �X�V�p�J�E���g
    gn_upd_tab_cnt := gn_upd_tab_cnt + 1;
--
    item_location_code_upd_tab(gn_upd_tab_cnt)     := ir_data.item_location_code;     -- ���q�ɃR�[�h
    item_code_upd_tab(gn_upd_tab_cnt)              := ir_data.item_code;              -- �i�ڃR�[�h
    frq_item_location_id_upd_tab(gn_upd_tab_cnt)   := ir_data.frq_item_location_id;   -- ��\�q��ID
    frq_item_location_code_upd_tab(gn_upd_tab_cnt) := ir_data.frq_item_location_code; -- ��\�q�ɃR�[�h
--
  EXCEPTION
--
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
  END set_upd_tab;
--
--
  /**********************************************************************************
   * Procedure Name   : ins_data
   * Description      : �ꊇ�o�^����(H-11)
   ***********************************************************************************/
  PROCEDURE ins_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_data'; -- �v���O������
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �ꊇ�o�^����
    -- ===============================
    FORALL ln_cnt_loop IN 1 .. pk_id_tab.COUNT
      INSERT INTO xxwsh_frq_item_locations  xfil      -- �q�ɕi�ڃA�h�I���}�X�^
        (xfil.pk_id                                   -- �q�ɕi��ID
        ,xfil.item_location_id                        -- ���q��ID
        ,xfil.item_location_code                      -- ���q�ɃR�[�h
        ,xfil.item_id                                 -- �i��ID
        ,xfil.item_code                               -- �i�ڃR�[�h
        ,xfil.frq_item_location_id                    -- ��\�q��ID
        ,xfil.frq_item_location_code                  -- ��\�q�ɃR�[�h
        ,xfil.created_by                              -- �쐬��
        ,xfil.creation_date                           -- �쐬��
        ,xfil.last_updated_by                         -- �ŏI�X�V��
        ,xfil.last_update_date                        -- �ŏI�X�V��
        ,xfil.last_update_login                       -- �ŏI�X�V���O�C��
        ,xfil.request_id                              -- �v��ID
        ,xfil.program_application_id                  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,xfil.program_id                              -- �R���J�����g�E�v���O����ID
        ,xfil.program_update_date                     -- �v���O�����X�V��
        )
      VALUES
        (pk_id_tab(ln_cnt_loop)                       -- �q�ɕi��ID
        ,item_location_id_ins_tab(ln_cnt_loop)        -- ���q��ID
        ,item_location_code_ins_tab(ln_cnt_loop)      -- ���q�ɃR�[�h
        ,item_id_ins_tab(ln_cnt_loop)                 -- �i��ID
        ,item_code_ins_tab(ln_cnt_loop)               -- �i�ڃR�[�h
        ,frq_item_location_id_ins_tab(ln_cnt_loop)    -- ��\�q��ID
        ,frq_item_location_code_ins_tab(ln_cnt_loop)  -- ��\�q�ɃR�[�h
        ,FND_GLOBAL.USER_ID                           -- �쐬��
        ,SYSDATE                                      -- �쐬��
        ,FND_GLOBAL.USER_ID                           -- �ŏI�X�V��
        ,SYSDATE                                      -- �ŏI�X�V��
        ,FND_GLOBAL.LOGIN_ID                          -- �ŏI�X�V���O�C��
        ,FND_GLOBAL.CONC_REQUEST_ID                   -- �v��ID
        ,FND_GLOBAL.PROG_APPL_ID                      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,FND_GLOBAL.CONC_PROGRAM_ID                   -- �R���J�����g�E�v���O����ID
        ,SYSDATE                                      -- �v���O�����X�V��
        );
--
--
  EXCEPTION
--
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
  END ins_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_data
   * Description      : �ꊇ�X�V����(H-12)
   ***********************************************************************************/
  PROCEDURE upd_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_data'; -- �v���O������
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �ꊇ�X�V����
    -- ===============================
    FORALL ln_cnt_loop IN 1 .. frq_item_location_code_upd_tab.COUNT
      UPDATE xxwsh_frq_item_locations  xfil      -- �q�ɕi�ڃA�h�I���}�X�^
      SET    xfil.frq_item_location_id   = frq_item_location_id_upd_tab(ln_cnt_loop)    -- ��\�q��ID
            ,xfil.frq_item_location_code = frq_item_location_code_upd_tab(ln_cnt_loop)  -- ��\�q�ɃR�[�h
            ,xfil.last_updated_by        = FND_GLOBAL.USER_ID                           -- �ŏI�X�V��
            ,xfil.last_update_date       = SYSDATE                                      -- �ŏI�X�V��
            ,xfil.last_update_login      = FND_GLOBAL.LOGIN_ID                          -- �ŏI�X�V���O�C��
            ,xfil.request_id             = FND_GLOBAL.CONC_REQUEST_ID                   -- �v��ID
            ,xfil.program_application_id = FND_GLOBAL.PROG_APPL_ID                      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,xfil.program_id             = FND_GLOBAL.CONC_PROGRAM_ID                   -- �R���J�����g�E�v���O����ID
            ,xfil.program_update_date    = SYSDATE                                      -- �v���O�����X�V��
      WHERE xfil.item_location_code      = item_location_code_upd_tab(ln_cnt_loop)      -- ���q��
      AND   xfil.item_code               = item_code_upd_tab(ln_cnt_loop)               -- �i�ڃR�[�h
      ;
--
  EXCEPTION
--
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
  END upd_data;
--
  /**********************************************************************************
   * Procedure Name   : del_data
   * Description      : �ꊇ�폜����(H-13)
   ***********************************************************************************/
  PROCEDURE del_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_data'; -- �v���O������
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �q�ɕi�ڃA�h�I���}�X�^�C���^�t�F�[�X�폜
    -- ===============================
    FORALL ln_count IN 1..request_id_tab.COUNT
      DELETE xxwsh_frq_item_locations_if xfili             -- �q�ɕi�ڃA�h�I���}�X�^�C���^�t�F�[�X
      WHERE  xfili.request_id = request_id_tab(ln_count)   -- �v��ID
      ;
--
  EXCEPTION
--
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
  END del_data;
--
  /**********************************************************************************
   * Procedure Name   : put_dump_msg
   * Description      : �f�[�^�_���v�ꊇ�o�͏���(H-14)
   ***********************************************************************************/
  PROCEDURE put_dump_msg(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_dump_msg'; -- �v���O������
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
    lv_msg  VARCHAR2(5000);  -- ���b�Z�[�W
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �f�[�^�_���v�ꊇ�o��
    -- ===============================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- �����f�[�^�i���o���j
    lv_msg  := SUBSTRB(
                 xxcmn_common_pkg.get_msg(
                   gv_xxcmn               -- ���W���[�������́FXXCMN
                  ,gv_msg_xxcmn00005)     -- ���b�Z�[�W�FAPP-XXCMN-00005 �����f�[�^�i���o���j
                ,1,5000);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_msg);
--
    -- ����f�[�^�_���v
    <<normal_dump_loop>>
    FOR ln_cnt_loop IN 1 .. normal_dump_tab.COUNT
    LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, normal_dump_tab(ln_cnt_loop));
    END LOOP normal_dump_loop;
--
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- �X�L�b�v�f�[�^�f�[�^�i���o���j
    lv_msg  := SUBSTRB(
                 xxcmn_common_pkg.get_msg(
                   gv_xxcmn               -- ���W���[�������́FXXCMN
                  ,gv_msg_xxcmn00007)     -- ���b�Z�[�W�FAPP-XXCMN-00007 �X�L�b�v�f�[�^�i���o���j
                ,1,5000);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_msg);
--
    -- �x���f�[�^�_���v
    <<warn_dump_loop>>
    FOR ln_cnt_loop IN 1 .. warn_dump_tab.COUNT
    LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, warn_dump_tab(ln_cnt_loop));
    END LOOP warn_dump_loop;
--
  EXCEPTION
--
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
  END put_dump_msg;
--
--
  /**********************************************************************************
   * Procedure Name   : ins_data_loop
   * Description      : �o�^�f�[�^�擾����(H-5)
   ***********************************************************************************/
  PROCEDURE ins_data_loop(
    it_request_id IN  xxwsh_frq_item_locations_if.request_id%TYPE,           -- �v��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_data_loop'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***\
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =============================
    -- H-5.�o�^�f�[�^�擾
    -- =============================
    <<ins_data_loop>>
    FOR lr_ins_data IN ins_cur(it_request_id) LOOP
      BEGIN
        -- =============================
        -- H-7.�}�X�^�f�[�^�`�F�b�N����
        -- =============================
        chk_master_data(
          ir_chk_data => lr_ins_data        -- �`�F�b�N�f�[�^
         ,ov_errbuf   => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode  => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg   => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        -- �G���[�̏ꍇ
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- �x���̏ꍇ
        ELSIF (lv_retcode = gv_status_warn) THEN
          RAISE skip_expt;
        END IF;
--
        -- =============================
        -- H-8.�Ó����`�F�b�N����
        -- =============================
        chk_consistency_data(
          ir_chk_data => lr_ins_data        -- �`�F�b�N�f�[�^
         ,ov_errbuf   => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode  => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg   => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        -- �G���[�̏ꍇ
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- �x���̏ꍇ
        ELSIF (lv_retcode = gv_status_warn) THEN
          RAISE skip_expt;
        END IF;
--
        -- =============================
        -- H-9.�o�^�pPL/SQL�\����
        -- =============================
        set_ins_tab(
          ir_data     => lr_ins_data        -- �`�F�b�N�f�[�^
         ,ov_errbuf   => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode  => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg   => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        -- �G���[�̏ꍇ
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- ����̏ꍇ
        ELSE
          -- ����f�[�^����
          gn_normal_cnt := gn_normal_cnt + 1;
--
          -- ����f�[�^�_���vPL/SQL�\����
          normal_dump_tab(gn_normal_cnt) := lr_ins_data.data_dump;
        END IF;
--
      EXCEPTION
        WHEN skip_expt THEN  -- �x���������A�X�L�b�v���Ď����R�[�h�̏������s���B
          -- OUT�p�����[�^���x���ɃZ�b�g
          ov_retcode := gv_status_warn;
          -- �X�L�b�v�����J�E���g
          gn_warn_cnt   := gn_warn_cnt + 1;
      END;
--
    END LOOP ins_data_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_data_loop;
--
  /**********************************************************************************
   * Procedure Name   : upd_data_loop
   * Description      : �X�V�f�[�^�擾����(H-6)
   ***********************************************************************************/
  PROCEDURE upd_data_loop(
    it_request_id IN  xxwsh_frq_item_locations_if.request_id%TYPE,           -- �v��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_data_loop'; -- �v���O������
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
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***\
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =============================
    -- H-6.�X�V�f�[�^�擾
    -- =============================
    <<upd_data_loop>>
    FOR lr_upd_data IN upd_cur(it_request_id) LOOP
      BEGIN
        -- =============================
        -- H-7.�}�X�^�f�[�^�`�F�b�N����
        -- =============================
        chk_master_data(
          ir_chk_data => lr_upd_data        -- �`�F�b�N�f�[�^
         ,ov_errbuf   => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode  => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg   => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        -- �G���[�̏ꍇ
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- �x���̏ꍇ
        ELSIF (lv_retcode = gv_status_warn) THEN
          RAISE skip_expt;
        END IF;
--
        -- =============================
        -- H-8.�Ó����`�F�b�N����
        -- =============================
        chk_consistency_data(
          ir_chk_data => lr_upd_data        -- �`�F�b�N�f�[�^
         ,ov_errbuf   => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode  => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg   => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        -- �G���[�̏ꍇ
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- �x���̏ꍇ
        ELSIF (lv_retcode = gv_status_warn) THEN
          RAISE skip_expt;
        END IF;
--
        -- =============================
        -- H-10.�X�V�pPL/SQL�\����
        -- =============================
        set_upd_tab(
          ir_data     => lr_upd_data        -- �`�F�b�N�f�[�^
         ,ov_errbuf   => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode  => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg   => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        -- �G���[�̏ꍇ
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
--
        -- ����̏ꍇ
        ELSE
          -- ����f�[�^����
          gn_normal_cnt := gn_normal_cnt + 1;
--
          -- ����f�[�^�_���vPL/SQL�\����
          normal_dump_tab(gn_normal_cnt) := lr_upd_data.data_dump;
        END IF;
--
      EXCEPTION
        WHEN skip_expt THEN  -- �x���������A�X�L�b�v���Ď����R�[�h�̏������s���B
          -- OUT�p�����[�^���x���ɃZ�b�g
          ov_retcode := gv_status_warn;
          -- �X�L�b�v�����J�E���g
          gn_warn_cnt   := gn_warn_cnt + 1;
      END;
--
    END LOOP upd_data_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_data_loop;
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    ln_request_count NUMBER;    -- �v��ID�J�E���g
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ===============================
    -- H-1.�֘A�f�[�^�擾����
    -- ===============================
    init_proc(
      ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- H-2.�v��ID�擾����
    -- ===============================
    get_request_id(
      ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- H-3.���b�N�擾����
    -- ===============================
    get_lock(
      ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �擾�����v��ID������LOOP
    -- ===============================
    <<request_id_loop>>
    FOR ln_count IN 1..request_id_tab.COUNT
    LOOP
      -- �ϐ�������
      -- �o�^�p�E�X�V�pPL/SQL�\�J�E���g
      gn_ins_tab_cnt := 0;
      gn_upd_tab_cnt := 0;
--
      -- �o�^�pPL/SQL�\
      pk_id_tab.DELETE;       -- �q�ɕi��ID
      item_location_id_ins_tab.DELETE;       -- ���q��ID
      item_location_code_ins_tab.DELETE;     -- ���q�ɃR�[�h
      item_id_ins_tab.DELETE;                -- �i��ID
      item_code_ins_tab.DELETE;              -- �i�ڃR�[�h
      frq_item_location_id_ins_tab.DELETE;   -- ��\�q��ID
      frq_item_location_code_ins_tab.DELETE; -- ��\�q�ɃR�[�h
--
      -- �X�V�pPL/SQL�\
      item_location_code_upd_tab.DELETE;     -- ���q�ɃR�[�h
      item_code_upd_tab.DELETE;              -- �i�ڃR�[�h
      frq_item_location_id_upd_tab.DELETE;   -- ��\�q��ID
      frq_item_location_code_upd_tab.DELETE; -- ��\�q�ɃR�[�h
--
      -- ===============================
      -- H-4.�d���f�[�^���O����
      -- ===============================
      del_duplication_data(
        it_request_id => request_id_tab(ln_count)    -- 1.�v��ID
       ,ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
--
      -- �x���̏ꍇ
      ELSIF (lv_retcode = gv_status_warn) THEN
        ov_retcode := gv_status_warn;
      END IF;
--
      -- ===============================
      -- H-5.�o�^�f�[�^�擾����
      -- ===============================
      ins_data_loop(
        it_request_id => request_id_tab(ln_count)    -- 1.�v��ID
       ,ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
--
      -- �x���̏ꍇ
      ELSIF (lv_retcode = gv_status_warn) THEN
        ov_retcode := gv_status_warn;
      END IF;
--
      -- ===============================
      -- H-6.�X�V�f�[�^�擾����
      -- ===============================
      upd_data_loop(
        it_request_id => request_id_tab(ln_count)    -- 1.�v��ID
       ,ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
--
      -- �x���̏ꍇ
      ELSIF (lv_retcode = gv_status_warn) THEN
        ov_retcode := gv_status_warn;
      END IF;
--
      -- ===============================
      -- H-11.�ꊇ�o�^����
      -- ===============================
      ins_data(
        ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- H-12.�ꊇ�X�V����
      -- ===============================
      upd_data(
        ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      -- �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP request_id_loop;
--
    -- ===============================
    -- H-13.�f�[�^�폜����
    -- ===============================
    del_data(
      ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- H-14.�f�[�^�_���v�ꊇ�o�͏���
    -- ===============================
    put_dump_msg(
      ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;

--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
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
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      lv_errbuf,   -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,  -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- H-15.���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�L�b�v�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxwsh920006c;
/
