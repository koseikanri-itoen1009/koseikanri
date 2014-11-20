CREATE OR REPLACE PACKAGE BODY xxwsh620001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620001c(body)
 * Description      : �݌ɕs���m�F���X�g
 * MD.050           : ����/�z��(���[) T_MD050_BPO_620
 * MD.070           : �݌ɕs���m�F���X�g T_MD070_BPO_62B
 * Version          : 1.8
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  fnc_chgdt_d            FUNCTION  : ���t�^�ϊ�(YYYY/MM/DD�`���̕����� �� ���t�^)
 *  fnc_chgdt_c            FUNCTION  : ���t�^�ϊ�(���t�^ �� YYYY/MM/DD�`���̕�����)
 *  prc_set_tag_data       PROCEDURE : �^�O���ݒ菈��
 *  prc_set_tag_data       PROCEDURE : �^�O���ݒ菈��(�J�n�E�I���^�O�p)
 *  prc_initialize         PROCEDURE : ��������
 *  prc_get_report_data    PROCEDURE : ���[�f�[�^�擾����
 *  prc_create_xml_data    PROCEDURE : XML��������
 *  fnc_convert_into_xml   FUNCTION  : XML�f�[�^�ϊ�
 *  submain                PROCEDURE : ���C�������v���V�[�W��
 *  main                   PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ------------------ -----------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -----------------------------------------------
 *  2008/05/05    1.0   Nozomi Kashiwagi   �V�K�쐬
 *  2008/07/08    1.1   Akiyoshi Shiina    �֑������u'�v�u"�v�u<�v�u>�v�u���v�Ή�
 *  2008/09/26    1.2   Hitomi Itou        T_TE080_BPO_600 �w�E38
 *                                         T_TE080_BPO_600 �w�E37
 *                                         T_S_533(PT�Ή� ���ISQL�ɕύX)
 *  2008/10/03    1.3   Hitomi Itou        T_TE080_BPO_600 �w�E37 �݌ɕs���̏ꍇ�A�˗����ɂ͕s������\������
 *  2008/11/13    1.4   Tsuyoki Yoshimoto  �����ύX#168
 *  2008/12/10    1.5   T.Miyata           �{��#637 �p�t�H�[�}���X�Ή�
 *  2008/12/10    1.6   Hitomi Itou        �{�ԏ�Q#650
 *  2009/01/07    1.7   Akiyoshi Shiina    �{�ԏ�Q#873
 *  2009/01/14    1.8   Hisanobu Sakuma    �{�ԏ�Q#661
 *  2009/01/20    1.9   Hisanobu Sakuma    �{�ԏ�Q#800
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
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
--###########################  �Œ蕔 END   ############################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  --*** ���������ʗ�O ***
  no_data_expt       EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- ���[���
  gc_pkg_name                CONSTANT  VARCHAR2(12) := 'xxwsh620001c' ;  -- �p�b�P�[�W��
  gc_report_id               CONSTANT  VARCHAR2(12) := 'XXWSH620001T' ;  -- ���[ID
  -- ���t�t�H�[�}�b�g
  gc_date_fmt_all            CONSTANT  VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS' ; -- �N���������b
  gc_date_fmt_ymd            CONSTANT  VARCHAR2(10) := 'YYYY/MM/DD' ;            -- �N����
  gc_date_fmt_hm             CONSTANT  VARCHAR2(10) := 'HH24:MI' ;               -- �����b
  gc_date_fmt_ymd_ja         CONSTANT  VARCHAR2(20) := 'YYYY"�N"MM"��"DD"��' ;   -- ����
  -- ����
  gc_time_start              CONSTANT  VARCHAR2(5) := '00:00' ;
  gc_time_end                CONSTANT  VARCHAR2(5) := '23:59' ;
  -- �o�̓^�O
  gc_tag_type_tag            CONSTANT  VARCHAR2(1)  := 'T' ;                 -- �O���[�v�^�O
  gc_tag_type_data           CONSTANT  VARCHAR2(1)  := 'D' ;                 -- �f�[�^�^�O
  -- �Ɩ����
  gc_biz_type_nm_ship        CONSTANT  VARCHAR2(4)  := '�o��' ;     -- �o��
  gc_biz_type_nm_move        CONSTANT  VARCHAR2(4)  := '�ړ�' ;     -- �ړ�
  -- �폜�E����t���O
  gc_delete_flg              CONSTANT  VARCHAR2(1)  := 'Y' ;        -- �N�x�s��
  -- �����^�C�v
  gc_doc_type_ship           CONSTANT  VARCHAR2(2)  := '10' ;       -- �o�׈˗�
  gc_doc_type_move           CONSTANT  VARCHAR2(2)  := '20' ;       -- �ړ�
  -- ���R�[�h�^�C�v
  gc_rec_type_shiji          CONSTANT  VARCHAR2(2)  := '10' ;       -- �w��
  ------------------------------
  -- �o�׊֘A
  ------------------------------
  -- �o�׎x���敪
  gc_ship_pro_kbn_s          CONSTANT  VARCHAR2(1)  := '1' ;        -- �o�׈˗�
  -- �󒍃J�e�S��
  gc_order_cate_ret          CONSTANT  VARCHAR2(10) := 'RETURN' ;   -- �ԕi(�󒍂̂�)
  -- �ŐV�t���O
  gc_new_flg                 CONSTANT  VARCHAR2(1)  := 'Y' ;        -- �ŐV�t���O
  -- �o�׈˗��X�e�[�^�X
  gc_ship_status_close       CONSTANT  VARCHAR2(2)  := '03' ;       -- ���ߍς�
  gc_ship_status_delete      CONSTANT  VARCHAR2(2)  := '99' ;       -- ���
-- 2009/01/07 v1.7 ADD START
  gc_ship_status_confirm     CONSTANT  VARCHAR2(2)  := '04' ;       -- �o�׎��ьv���
-- 2009/01/07 v1.7 ADD END

  ------------------------------
  -- �ړ��֘A
  ------------------------------
  -- �ړ��^�C�v
  gc_mov_type_not_ship       CONSTANT  VARCHAR2(5)  := '2' ;        -- �ϑ��Ȃ�
  -- �ړ��X�e�[�^�X
  gc_move_status_ordered     CONSTANT  VARCHAR2(2)  := '02' ;       -- �˗���
-- 2008/11/13 v1.4 T.Yoshimoto Add Start
  -- �w���Ȃ����ы敪
  gc_move_instr_actual_class      CONSTANT  VARCHAR2(1)  := 'Y' ;        -- �w���Ȃ�����
-- 2008/11/13 v1.4 T.Yoshimoto Add End
-- 2008/12/10 v1.5 H.Itou Add Start
  -- �ʒm�X�e�[�^�X
  gc_notif_status_ktz        CONSTANT  VARCHAR2(2)  := '40' ;       -- �m��ʒm��
-- 2009/01/07 v1.7 ADD START
  gc_notif_status_mt         CONSTANT  VARCHAR2(2)  := '10' ;       -- ���ʒm
  gc_notif_status_sty        CONSTANT  VARCHAR2(2)  := '20' ;       -- �Ēʒm�v
-- 2009/01/07 v1.7 ADD END
-- 2008/12/10 v1.5 H.Itou Add End
  ------------------------------
  -- �N�C�b�N�R�[�h�֘A
  ------------------------------
  gc_lookup_cd_block         CONSTANT  VARCHAR2(30)  := 'XXCMN_D12' ;          -- �����u���b�N
  gc_lookup_cd_lot_status    CONSTANT  VARCHAR2(30)  := 'XXCMN_LOT_STATUS' ;   -- ���b�g�X�e�[�^�X
  gc_lookup_cd_conreq        CONSTANT  VARCHAR2(30)  := 'XXWSH_LG_CONFIRM_REQ_CLASS' ; -- �m�F�˗�
  ------------------------------
  -- �v���t�@�C���֘A
  ------------------------------
  gc_prof_name_item_div      CONSTANT VARCHAR2(30)  := 'XXCMN_ITEM_DIV_SECURITY' ; -- ���i�敪
  ------------------------------
  -- ���b�Z�[�W�֘A
  ------------------------------
  --�A�v���P�[�V������
  gc_application_wsh         CONSTANT VARCHAR2(5)   := 'XXWSH' ;            -- ��޵�:�o�ץ������z��
  gc_application_cmn         CONSTANT VARCHAR2(5)   := 'XXCMN' ;            -- ��޵�:Ͻ���o�������
  --���b�Z�[�WID
  gc_msg_id_not_get_prof     CONSTANT  VARCHAR2(15) := 'APP-XXWSH-12301' ;  -- ���̧�َ擾�װ
  gc_msg_id_no_data          CONSTANT  VARCHAR2(15) := 'APP-XXCMN-10122' ;  -- ���[0���G���[
  gc_msg_id_prm_chk          CONSTANT  VARCHAR2(15) := 'APP-XXWSH-12256' ;  -- ���Ұ������װ
  --���b�Z�[�W-�g�[�N����
  gc_msg_tkn_nm_prof         CONSTANT  VARCHAR2(10) := 'PROF_NAME' ;        -- �v���t�@�C����
  --���b�Z�[�W-�g�[�N���l
  gc_msg_tkn_val_prof_prod   CONSTANT  VARCHAR2(30) := 'XXCMN�F���i�敪(�Z�L�����e�B)' ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���R�[�h�^�錾�p�e�[�u���ʖ��錾
  xoha   xxwsh_order_headers_all%ROWTYPE ;        -- �󒍃w�b�_�A�h�I��
  xola   xxwsh_order_lines_all%ROWTYPE ;          -- �󒍖��׃A�h�I��
  xmrih  xxinv_mov_req_instr_headers%ROWTYPE ;    -- �ړ��˗�/�w���w�b�_(�A�h�I��)
  xmril  xxinv_mov_req_instr_lines%ROWTYPE ;      -- �ړ��˗�/�w������(�A�h�I��)
  xmld   xxinv_mov_lot_details%ROWTYPE ;          -- �ړ����b�g�ڍ�(�A�h�I��)
  ilm    ic_lots_mst%ROWTYPE ;                    -- OPM���b�g�}�X�^
  xottv  xxwsh_oe_transaction_types2_v%ROWTYPE ;  -- �󒍃^�C�v���VIEW2
  xtc    xxwsh_tightening_control%ROWTYPE ;       -- �o�׈˗����ߊǗ�(�A�h�I��)
  xilv   xxcmn_item_locations2_v%ROWTYPE ;        -- OPM�ۊǏꏊ���(�o�Ɍ�)
  xcav   xxcmn_cust_accounts2_v%ROWTYPE ;         -- �ڋq���
  xcasv  xxcmn_cust_acct_sites2_v%ROWTYPE ;       -- �ڋq�T�C�g���
  ximv   xxcmn_item_mst2_v%ROWTYPE ;              -- OPM�i�ڏ��
  xicv   xxcmn_item_categories4_v%ROWTYPE ;       -- OPM�i�ڃJ�e�S���������
  xlvv   xxcmn_lookup_values2_v%ROWTYPE ;         -- �N�C�b�N�R�[�h
--
  ------------------------------
  -- ���̓p�����[�^�֘A
  ------------------------------
  -- ���̓p�����[�^�i�[�p���R�[�h
  TYPE rec_param_data IS RECORD(
     block1              xilv.distribution_block%TYPE      -- 01:�u���b�N1
    ,block2              xilv.distribution_block%TYPE      -- 02:�u���b�N2
    ,block3              xilv.distribution_block%TYPE      -- 03:�u���b�N3
    ,tighten_date        DATE                              -- 04:���ߎ��{��
    ,tighten_time_from   VARCHAR2(5)                       -- 05:���ߎ��{����From
    ,tighten_time_to     VARCHAR2(5)                       -- 06:���ߎ��{����To
    ,shipped_cd          xoha.deliver_from%TYPE            -- 07:�o�Ɍ�
    ,item_cd             xola.shipping_item_code%TYPE      -- 08:�i��
    ,shipped_date_from   DATE                              -- 09:�o�ɓ�From  ���K�{
    ,shipped_date_to     DATE                              -- 10:�o�ɓ�To    ���K�{
  );
--
  ------------------------------
  -- �o�̓f�[�^�֘A
  ------------------------------
  -- �o�̓f�[�^�i�[�p���R�[�h
  TYPE rec_report_data IS RECORD(
     block_cd          xilv.distribution_block%TYPE          -- �u���b�N�R�[�h
    ,block_nm          xlvv.meaning%TYPE                     -- �u���b�N����
    ,shipped_cd        xoha.deliver_from%TYPE                -- �o�Ɍ��R�[�h
    ,shipped_nm        xilv.description%TYPE                 -- �o�Ɍ���
    ,item_cd           xola.shipping_item_code%TYPE          -- �i�ڃR�[�h
    ,item_nm           ximv.item_name%TYPE                   -- �i�ږ���
    ,shipped_date      xoha.schedule_ship_date%TYPE          -- �o�ɓ�
    ,arrival_date      xoha.schedule_arrival_date%TYPE       -- ����
    ,biz_type          VARCHAR2(4)                           -- �Ɩ����
    ,req_move_no       xoha.request_no%TYPE                  -- �˗�No/�ړ�No
    ,base_cd           xoha.head_sales_branch%TYPE           -- �Ǌ����_
    ,base_nm           xcav.party_short_name%TYPE            -- �Ǌ����_����
    ,delivery_to_cd    xoha.deliver_to%TYPE                  -- �z����/���ɐ�
    ,delivery_to_nm    xcasv.party_site_full_name%TYPE       -- �z���於��
    ,description       xoha.shipping_instructions%TYPE       -- �E�v
    ,conf_req          xlvv.meaning%TYPE                     -- �m�F�˗�
    ,de_prod_date      xola.warning_date%TYPE                -- �w�萻����
-- 2008/09/26 H.Itou Add Start T_TE080_BPO_600�w�E38
    ,de_prod_date_sort xola.warning_date%TYPE                -- �w�萻����(�\�[�g�p)
-- 2008/09/26 H.Itou Add End
    ,prod_date         ilm.attribute1%TYPE                   -- ������
    ,best_before_date  ilm.attribute3%TYPE                   -- �ܖ�����
    ,native_sign       ilm.attribute2%TYPE                   -- �ŗL�L��
    ,lot_no            xmld.lot_no%TYPE                      -- ���b�gNo
    ,lot_status        xlvv.meaning%TYPE                     -- �i��
    ,req_qty           NUMBER                                -- �˗���
    ,ins_qty           NUMBER                                -- �s����
    ,reserve_order     xcav.reserve_order%TYPE               -- ������
    ,time_from         xoha.arrival_time_from%TYPE           -- ���Ԏw��From
  );
  type_report_data      rec_report_data;
  TYPE list_report_data IS TABLE OF rec_report_data INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_param              rec_param_data ;        -- ���̓p�����[�^���
  gt_report_data        list_report_data ;      -- �o�̓f�[�^
  gt_xml_data_table     xml_data ;              -- XML�f�[�^
  gv_dept_cd            VARCHAR2(10) ;          -- �S������
  gv_dept_nm            VARCHAR2(14) ;          -- �S����
--
  -- �v���t�@�C���l�擾���ʊi�[�p
  gv_user_id            fnd_user.user_id%TYPE;  -- ���[�UID
  gv_prod_kbn           VARCHAR2(1);            -- ���i�敪
--
  /**********************************************************************************
   * Function Name    : fnc_chgdt_d
   * Description      : ���t�^�ϊ�(YYYY/MM/DD�`���̕����� �� ���t�^)
   *                  ������̓��t(YYYY/MM/DD�`��)����t�^�ɕϊ����ĕԋp
   *                  (��F2008/04/01 �� 01-APR-08)
   ***********************************************************************************/
  FUNCTION fnc_chgdt_d(
    iv_date  IN  VARCHAR2  -- YYYY/MM/DD�`���̓��t
  )RETURN DATE
  IS
  BEGIN
    RETURN( FND_DATE.STRING_TO_DATE(iv_date, gc_date_fmt_ymd) ) ;
  END fnc_chgdt_d;
--
  /**********************************************************************************
   * Function Name    : fnc_chgdt_c
   * Description      : ���t�^�ϊ�(���t�^ �� YYYY/MM/DD�`���̕�����)
   *                  ���t�^���uYYYY/MM/DD�`���v�̕�����ɕϊ����ĕԋp
   *                  (��F01-APR-08 �� 2008/04/01 )
   ***********************************************************************************/
  FUNCTION fnc_chgdt_c(
    id_date  IN  DATE
  )RETURN VARCHAR2
  IS
  BEGIN
    RETURN( TO_CHAR(id_date, gc_date_fmt_ymd) ) ;
  END fnc_chgdt_c;
--
  /**********************************************************************************
   * Procedure Name   : prc_set_tag_data
   * Description      : �^�O���ݒ菈��
   ***********************************************************************************/
  PROCEDURE prc_set_tag_data(
     iv_tag_name       IN  VARCHAR2                 -- �^�O��
    ,iv_tag_value      IN  VARCHAR2                 -- �f�[�^
    ,iv_tag_type       IN  VARCHAR2  DEFAULT NULL   -- �f�[�^
  )
  IS
    ln_data_index  NUMBER ;    -- XML�f�[�^�̃C���f�b�N�X
  BEGIN
    ln_data_index := gt_xml_data_table.COUNT + 1 ;
--
    -- �^�O����ݒ�
    gt_xml_data_table(ln_data_index).tag_name := iv_tag_name ;
--
    IF ((iv_tag_value IS NULL) AND (iv_tag_type = gc_tag_type_tag)) THEN
      -- �O���[�v�^�O�ݒ�
      gt_xml_data_table(ln_data_index).tag_type := gc_tag_type_tag;
    ELSE
      -- �f�[�^�^�O�ݒ�
      gt_xml_data_table(ln_data_index).tag_type := gc_tag_type_data;
      gt_xml_data_table(ln_data_index).tag_value := iv_tag_value;
    END IF;
  END prc_set_tag_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_set_tag_data
   * Description      : �^�O���ݒ菈��(�J�n�E�I���^�O�p)
   ***********************************************************************************/
  PROCEDURE prc_set_tag_data(
     iv_tag_name       IN  VARCHAR2  -- �^�O��
  )
  IS
  BEGIN
    prc_set_tag_data(iv_tag_name, NULL, gc_tag_type_tag);
  END prc_set_tag_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : ��������
   ***********************************************************************************/
  PROCEDURE prc_initialize(
    ov_errbuf     OUT  VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT  VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT  VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT  VARCHAR2(100) := 'prc_initialize' ;  -- �v���O������
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
    -- *** ���[�J���E��O���� ***
    prm_check_expt    EXCEPTION ;     -- �p�����[�^�`�F�b�N��O
    get_prof_expt     EXCEPTION ;     -- �v���t�@�C���擾��O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �p�����[�^�`�F�b�N
    -- ====================================================
    -- ���ߎ��{���A���ߎ��{���ԃ`�F�b�N
    IF ((gt_param.tighten_date IS NULL)
      AND ((gt_param.tighten_time_from IS NOT NULL) OR (gt_param.tighten_time_to IS NOT NULL))) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh, gc_msg_id_prm_chk ) ;
      RAISE prm_check_expt ;
    END IF;
--
    -- ====================================================
    -- �v���t�@�C���擾
    -- ====================================================
    -- ���[�UID
    gv_user_id := FND_GLOBAL.USER_ID ;
--
    -- �E�ӁF���i�敪(�Z�L�����e�B)
    gv_prod_kbn := FND_PROFILE.VALUE(gc_prof_name_item_div) ;
    IF (gv_prod_kbn IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_not_get_prof
                                            ,gc_msg_tkn_nm_prof
                                            ,gc_msg_tkn_val_prof_prod
                                           ) ;
      RAISE get_prof_expt ;
    END IF ;
--
  EXCEPTION
    --*** �p�����[�^�`�F�b�N��O�n���h�� ***
    WHEN prm_check_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
    --*** �v���t�@�C���擾��O�n���h�� ***
    WHEN get_prof_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_initialize;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���[�f�[�^�擾����
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
    ov_errbuf      OUT   VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT   VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT   VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_report_data' ;  -- �v���O������
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
    -- *** ���[�J���E�J�[�\�� ***
-- 2008/09/26 H.Itou Del Start T_S_533(PT�Ή�)
--    CURSOR cur_data
--    IS
--      ----------------------------------------------------------------------------------
--      -- �s�����擾(�o��)
--      ----------------------------------------------------------------------------------
--      SELECT
--        ----------------------------------------------------------------------------------
--        -- �w�b�_��
--        ----------------------------------------------------------------------------------
--         xilv.distribution_block      AS  block_cd            -- �u���b�N�R�[�h
--        ,xlvv1.meaning                AS  block_nm            -- �u���b�N����
--        ,xoha.deliver_from            AS  shipped_cd          -- �o�Ɍ��R�[�h
--        ,xilv.description             AS  shipped_nm          -- �o�Ɍ���
--        ----------------------------------------------------------------------------------
--        -- ���ו�
--        ----------------------------------------------------------------------------------
--        ,xola.shipping_item_code      AS  item_cd             -- �i�ڃR�[�h
--        ,ximv.item_name               AS  item_nm             -- �i�ږ���
--        ,xoha.schedule_ship_date      AS  shipped_date        -- �o�ɓ�
--        ,xoha.schedule_arrival_date   AS  arrival_date        -- ����
--        ,TO_CHAR(gc_biz_type_nm_ship) AS  biz_type            -- �Ɩ����
--        ,xoha.request_no              AS  req_move_no         -- �˗�No/�ړ�No
--        ,xoha.head_sales_branch       AS  base_cd             -- �Ǌ����_
--        ,xcav.party_short_name        AS  base_nm             -- �Ǌ����_����
--        ,xoha.deliver_to              AS  delivery_to_cd      -- �z����/���ɐ�
--        ,xcasv.party_site_full_name   AS  delivery_to_nm      -- �z���於��
--        ,SUBSTRB(xoha.shipping_instructions, 1, 40)
--                                      AS  description         -- �E�v
--        ,xlvv2.meaning                AS  conf_req            -- �m�F�˗�
--        ,CASE
--           WHEN xola.warning_date IS NULL THEN xola.designated_production_date
--           ELSE xola.warning_date
--         END                          AS  de_prod_date        -- �w�萻����
--        ,NVL(xola.warning_date, NVL(xola.designated_production_date, TO_DATE('19000101', 'YYYYMMDD'))) 
--                                      AS  de_prod_date_sort   -- �w�萻����(�\�[�g�p) 2008/09/26 H.Itou Add T_TE080_BPO_600�w�E38�Ή�
--        ,NULL                         AS  prod_date           -- ������
--        ,NULL                         AS  best_before_date    -- �ܖ�����
--        ,NULL                         AS  native_sign         -- �ŗL�L��
--        ,NULL                         AS  lot_no              -- ���b�gNo
--        ,NULL                         AS  lot_status          -- �i��
---- 2008/09/26 H.Itou Mod Start T_TE080_BPO_600�w�E37�Ή�
----        ,TO_NUMBER(0)                 AS  req_qty             -- �˗���
--        ,CASE 
--           WHEN ximv.conv_unit IS NULL THEN xola.quantity 
--           ELSE                            (xola.quantity / ximv.num_of_cases) 
--         END                          AS  req_qty '                 -- �˗��� 2008/09/26 H.Itou Mod T_TE080_BPO_600�w�E37�Ή�
---- 2008/09/26 H.Itou Mod End
--        ,CASE
--          WHEN ximv.conv_unit IS NULL THEN
--            (xola.quantity - NVL(xola.reserved_quantity, 0))
--          ELSE ((xola.quantity - NVL(xola.reserved_quantity, 0))
--               / TO_NUMBER(
--                   CASE
--                     WHEN ximv.num_of_cases > 0 THEN  ximv.num_of_cases
--                     ELSE TO_CHAR(1)
--                   END)
--          )
--         END                          AS  ins_qty             -- �s����
--        ,xcav.reserve_order           AS  reserve_order       -- ������
--        ,xoha.arrival_time_from       AS  time_from           -- ���Ԏw��From
--      FROM
--         xxwsh_order_headers_all        xoha    -- 01:�󒍃w�b�_�A�h�I��
--        ,xxwsh_order_lines_all          xola    -- 02:�󒍖��׃A�h�I��
--        ,xxwsh_oe_transaction_types2_v  xottv   -- 03:�󒍃^�C�v���
--        ,xxwsh_tightening_control       xtc     -- 04:�o�׈˗����ߊǗ�(�A�h�I��)
--        ,xxcmn_item_locations2_v        xilv    -- 05:OPM�ۊǏꏊ���
--        ,xxcmn_cust_accounts2_v         xcav    -- 06:�ڋq���(�Ǌ����_)
--        ,xxcmn_cust_acct_sites2_v       xcasv   -- 07:�ڋq�T�C�g���(�o�א�)
--        ,xxcmn_item_mst2_v              ximv    -- 08:OPM�i�ڏ��
--        ,xxcmn_lookup_values2_v         xlvv1   -- 09:�N�C�b�N�R�[�h(�����u���b�N)
--        ,xxcmn_lookup_values2_v         xlvv2   -- 10:�N�C�b�N�R�[�h(�����S���m�F�˗��敪)
--      WHERE
--        ----------------------------------------------------------------------------------
--        -- �w�b�_���
--        ----------------------------------------------------------------------------------
--        -- 03:�󒍃^�C�v���
--             xottv.shipping_shikyu_class  =  gc_ship_pro_kbn_s  -- �o�׎x���敪:�o�׈˗�
--        AND  xottv.order_category_code   <>  gc_order_cate_ret  -- �󒍃J�e�S��:�ԕi
--        -- 01:�󒍃w�b�_�A�h�I��
--        AND  xoha.order_type_id           =  xottv.transaction_type_id
--        AND  xoha.req_status             >=  gc_ship_status_close      -- �X�e�[�^�X:���ߍς�
--        AND  xoha.req_status             <>  gc_ship_status_delete     -- �X�e�[�^�X:���
--        AND  xoha.latest_external_flag    =  gc_new_flg                -- �ŐV�t���O
--        AND  xoha.prod_class              =  gv_prod_kbn
--        AND  xoha.schedule_ship_date     >=  gt_param.shipped_date_from
--        AND  xoha.schedule_ship_date     <=  gt_param.shipped_date_to
--        -- 04:�o�׈˗����ߊǗ�(�A�h�I��)
--        AND  xoha.tightening_program_id  = xtc.concurrent_id(+)
--        AND  (gt_param.tighten_date IS NULL
--          OR  TRUNC(xtc.tightening_date)  = TRUNC(gt_param.tighten_date)
--        )
--        AND  (xtc.tightening_date IS NULL
--          OR (TO_CHAR(xtc.tightening_date, gc_date_fmt_hm)
--              >= NVL(gt_param.tighten_time_from, gc_time_start)
--            AND  TO_CHAR(xtc.tightening_date, gc_date_fmt_hm)
--              <= NVL(gt_param.tighten_time_to, gc_time_end)
--          )
--        )
--        -- 05:OPM�ۊǏꏊ���
--        AND  xoha.deliver_from_id = xilv.inventory_location_id
--        AND  (
--              xilv.distribution_block = gt_param.block1
--          OR  xilv.distribution_block = gt_param.block2
--          OR  xilv.distribution_block = gt_param.block3
--          OR  xoha.deliver_from = gt_param.shipped_cd
--          OR  ( gt_param.block1 IS NULL
--            AND gt_param.block2 IS NULL
--            AND gt_param.block3 IS NULL
--            AND gt_param.shipped_cd IS NULL
--          )
--        )
--        -- 06:�ڋq���(�Ǌ����_)
--        AND  xoha.head_sales_branch = xcav.party_number
--        -- 07:�ڋq�T�C�g���(�o�א�)
--        AND  xoha.deliver_to_id     = xcasv.party_site_id
--        ----------------------------------------------------------------------------------
--        -- ���׏��
--        ----------------------------------------------------------------------------------
--        -- 02:�󒍖��׃A�h�I��
--        AND  xoha.order_header_id =  xola.order_header_id
--        AND  xola.delete_flag    <>  gc_delete_flg
--        -- 08:OPM�i�ڏ��
--        AND  (gt_param.item_cd IS NULL
--           OR xola.shipping_item_code = gt_param.item_cd
--        )
--        AND  xola.shipping_inventory_item_id = ximv.inventory_item_id
--        ----------------------------------------------------------------------------------
--        -- �s�����擾����
--        ----------------------------------------------------------------------------------
--        AND  ((xola.quantity - xola.reserved_quantity) > 0
--           OR  xola.reserved_quantity IS NULL
--        )
--        ----------------------------------------------------------------------------------
--        -- �N�C�b�N�R�[�h
--        ----------------------------------------------------------------------------------
--        -- 09:�N�C�b�N�R�[�h(�����u���b�N)
--        AND  xlvv1.lookup_type = gc_lookup_cd_block
--        AND  xilv.distribution_block = xlvv1.lookup_code
--        -- 10:�N�C�b�N�R�[�h(�����S���m�F�˗��敪)
--        AND  xlvv2.lookup_type = gc_lookup_cd_conreq
--        AND  xoha.confirm_request_class = xlvv2.lookup_code
--        ----------------------------------------------------------------------------------
--        -- �K�p��
--        ----------------------------------------------------------------------------------
--        -- 06:�ڋq���(�Ǌ����_)
--        AND  xcav.start_date_active  <= xoha.schedule_ship_date
--        AND  (xcav.end_date_active IS NULL
--          OR  xcav.end_date_active  >= xoha.schedule_ship_date)
--        -- 07:�ڋq�T�C�g���(�o�א�)
--        AND  xcasv.start_date_active <= xoha.schedule_ship_date
--        AND  (xcasv.end_date_active IS NULL
--          OR  xcasv.end_date_active >= xoha.schedule_ship_date)
--        -- 08:OPM�i�ڏ��
--        AND  ximv.start_date_active  <= xoha.schedule_ship_date
--        AND  (ximv.end_date_active IS NULL
--          OR  ximv.end_date_active  >= xoha.schedule_ship_date)
--      ----------------------------------------------------------------------------------
--      -- �s���������̎擾(�o��)
--      ----------------------------------------------------------------------------------
--      UNION ALL
--      SELECT
--        ----------------------------------------------------------------------------------
--        -- �w�b�_��
--        ----------------------------------------------------------------------------------
--         xilv.distribution_block      AS  block_cd            -- �u���b�N�R�[�h
--        ,xlvv1.meaning                AS  block_nm            -- �u���b�N����
--        ,xoha.deliver_from            AS  shipped_cd          -- �o�Ɍ��R�[�h
--        ,xilv.description             AS  shipped_nm          -- �o�Ɍ���
--        ----------------------------------------------------------------------------------
--        -- ���ו�
--        ----------------------------------------------------------------------------------
--        ,xola.shipping_item_code      AS  item_cd             -- �i�ڃR�[�h
--        ,ximv.item_name               AS  item_nm             -- �i�ږ���
--        ,xoha.schedule_ship_date      AS  shipped_date        -- �o�ɓ�
--        ,xoha.schedule_arrival_date   AS  arrival_date        -- ����
--        ,TO_CHAR(gc_biz_type_nm_ship) AS  biz_type            -- �Ɩ����
--        ,xoha.request_no              AS  req_move_no         -- �˗�No/�ړ�No
--        ,xoha.head_sales_branch       AS  base_cd             -- �Ǌ����_
--        ,xcav.party_short_name        AS  base_nm             -- �Ǌ����_����
--        ,xoha.deliver_to              AS  delivery_to_cd      -- �z����/���ɐ�
--        ,xcasv.party_site_full_name   AS  delivery_to_nm      -- �z���於��
--        ,SUBSTRB(xoha.shipping_instructions, 1, 40) 
--                                      AS  description         -- �E�v
--        ,xlvv2.meaning                AS  conf_req            -- �m�F�˗�
--        ,CASE
--           WHEN xola.warning_date IS NULL THEN xola.designated_production_date
--           ELSE xola.warning_date
--         END                          AS  de_prod_date        -- �w�萻����
--        ,NVL(xola.warning_date, NVL(xola.designated_production_date, TO_DATE('19000101', 'YYYYMMDD'))) 
--                                      AS  de_prod_date_sort   -- �w�萻����(�\�[�g�p) 2008/09/26 H.Itou Add T_TE080_BPO_600�w�E38�Ή�
--        ,ilm.attribute1               AS  prod_date           -- ������
--        ,ilm.attribute3               AS  best_before_date    -- �ܖ�����
--        ,ilm.attribute2               AS  native_sign         -- �ŗL�L��
--        ,xmld.lot_no                  AS  lot_no              -- ���b�gNo
--        ,xlvv3.meaning                AS  lot_status          -- �i��
--        ,CASE
--          WHEN ximv.conv_unit IS NULL THEN xmld.actual_quantity
--          ELSE (xmld.actual_quantity / TO_NUMBER(
--                                         CASE
--                                           WHEN ximv.num_of_cases > 0 THEN  ximv.num_of_cases
--                                           ELSE TO_CHAR(1)
--                                         END)
--          )
--         END                          AS  req_qty             -- �˗���
--        ,TO_NUMBER(0)                 AS  ins_qty             -- �s����
--        ,xcav.reserve_order           AS  reserve_order       -- ������
--        ,xoha.arrival_time_from       AS  time_from           -- ���Ԏw��From
--      FROM
--        (
--          ----------------------------------------------------------------------------------
--          -- �����ϕ��𒊏o���邽�߂̕s���i�ڂ̎擾
--          ----------------------------------------------------------------------------------
--          SELECT
--             sub_data.shipped_cd         AS  shipped_cd    -- �o�׌��ۊǏꏊ(�o�Ɍ��ۊǏꏊ)
--            ,sub_data.item_cd            AS  item_cd       -- �o�וi��(�i��)
--            ,MAX(sub_data.shipped_date)  AS  shipped_date  -- �o�ח\���(�o�ɗ\���)
--          FROM
--            (
--              ----------------------------------------------------------------------------------
--              -- �����ϕ��𒊏o���邽�߂̕s���i�ڂ̎擾(�o��)
--              ----------------------------------------------------------------------------------
--              SELECT
--                 xoha.deliver_from             AS  shipped_cd    -- �o�׌��ۊǏꏊ
--                ,xola.shipping_item_code       AS  item_cd       -- �o�וi��
--                ,xoha.schedule_ship_date       AS  shipped_date  -- �o�ח\���
--              FROM
--                 xxwsh_order_headers_all        xoha    -- 01:�󒍃w�b�_�A�h�I��
--                ,xxwsh_order_lines_all          xola    -- 02:�󒍖��׃A�h�I��
--                ,xxwsh_oe_transaction_types2_v  xottv   -- 03:�󒍃^�C�v���
--                ,xxwsh_tightening_control       xtc     -- 04:�o�׈˗����ߊǗ�(�A�h�I��)
--                ,xxcmn_item_locations2_v        xilv    -- 05:OPM�ۊǏꏊ���
--              WHERE
--                ----------------------------------------------------------------------------------
--                -- �w�b�_���
--                ----------------------------------------------------------------------------------
--                -- 01:�󒍃w�b�_�A�h�I��
--                     xoha.order_type_id       = xottv.transaction_type_id
--                AND  xoha.schedule_ship_date >= TO_DATE(gt_param.shipped_date_from)
--                AND  xoha.schedule_ship_date <= TO_DATE(gt_param.shipped_date_to)
--                AND  xoha.latest_external_flag  =  gc_new_flg    -- �ŐV�t���O
--                -- 04:�o�׈˗����ߊǗ�(�A�h�I��)
--                AND  xoha.tightening_program_id  = xtc.concurrent_id(+)
--                AND  (gt_param.tighten_date IS NULL
--                  OR  TRUNC(xtc.tightening_date)  = TRUNC(gt_param.tighten_date)
--                )
--                AND  (xtc.tightening_date IS NULL
--                  OR (TO_CHAR(xtc.tightening_date, gc_date_fmt_hm)
--                      >= NVL(gt_param.tighten_time_from, gc_time_start)
--                    AND  TO_CHAR(xtc.tightening_date, gc_date_fmt_hm)
--                      <= NVL(gt_param.tighten_time_to, gc_time_end)
--                  )
--                )
--                -- 05:OPM�ۊǏꏊ���
--                AND  xoha.deliver_from_id = xilv.inventory_location_id
--                AND  (
--                      xilv.distribution_block = gt_param.block1
--                  OR  xilv.distribution_block = gt_param.block2
--                  OR  xilv.distribution_block = gt_param.block3
--                  OR  xoha.deliver_from = gt_param.shipped_cd
--                  OR  ( gt_param.block1 IS NULL
--                    AND gt_param.block2 IS NULL
--                    AND gt_param.block3 IS NULL
--                    AND gt_param.shipped_cd IS NULL
--                  )
--                )
--                ----------------------------------------------------------------------------------
--                -- ���׏��
--                ----------------------------------------------------------------------------------
--                -- 02:�󒍖��׃A�h�I��
--                AND  xoha.order_header_id = xola.order_header_id
--                AND  xola.delete_flag    <>  gc_delete_flg
--                -- 10:OPM�i�ڏ��
--                AND  (gt_param.item_cd IS NULL
--                   OR xola.shipping_item_code = gt_param.item_cd
--                )
--                AND  xoha.prod_class = gv_prod_kbn
--                ----------------------------------------------------------------------------------
--                -- �s�����擾����
--                ----------------------------------------------------------------------------------
--                AND  ((xola.quantity - xola.reserved_quantity) > 0
--                   OR xola.reserved_quantity IS NULL
--                )
--              ----------------------------------------------------------------------------------
--              -- �����ϕ��𒊏o���邽�߂̕s���i�ڂ̎擾(�ړ�)
--              ----------------------------------------------------------------------------------
--              UNION ALL
--              SELECT
--                 xmrih.shipped_locat_code       AS  shipped_cd   -- �o�Ɍ��ۊǏꏊ
--                ,xmril.item_code                AS  item_cd      -- �i��
--                ,xmrih.schedule_ship_date       AS  shipped_date -- �o�ɗ\���
--              FROM
--                 xxinv_mov_req_instr_headers    xmrih     -- 01:�ړ��˗�/�w���w�b�_�i�A�h�I���j
--                ,xxinv_mov_req_instr_lines      xmril     -- 02:�ړ��˗�/�w�����ׁi�A�h�I���j
--                ,xxcmn_item_locations2_v        xilv1     -- 03:OPM�ۊǏꏊ���(�o�Ɍ�)
--              WHERE
--                ----------------------------------------------------------------------------------
--                -- �w�b�_���
--                ----------------------------------------------------------------------------------
--                -- 01:�ړ��˗�/�w���w�b�_�i�A�h�I���j
--                     xmrih.schedule_ship_date >= TO_DATE(gt_param.shipped_date_from)
--                AND  xmrih.schedule_ship_date <= TO_DATE(gt_param.shipped_date_to)
--                -- 03:OPM�ۊǏꏊ���(�o�Ɍ�)
--                AND  xilv1.inventory_location_id = xmrih.shipped_locat_id
--                AND  (
--                      xilv1.distribution_block = gt_param.block1
--                  OR  xilv1.distribution_block = gt_param.block2
--                  OR  xilv1.distribution_block = gt_param.block3
--                  OR  xmrih.shipped_locat_code = gt_param.shipped_cd
--                  OR  (  gt_param.block1 IS NULL
--                    AND  gt_param.block2 IS NULL
--                    AND  gt_param.block3 IS NULL
--                    AND  gt_param.shipped_cd IS NULL
--                  )
--                )
--                ----------------------------------------------------------------------------------
--                -- ���׏��
--                ----------------------------------------------------------------------------------
--                -- 02:�ړ��˗�/�w�����ׁi�A�h�I���j
--                AND  xmrih.mov_hdr_id = xmril.mov_hdr_id
--                AND  xmril.delete_flg  <>  gc_delete_flg
--                AND  (gt_param.item_cd IS NULL
--                  OR  xmril.item_code = gt_param.item_cd
--                )
--                AND  xmrih.item_class = gv_prod_kbn
--                ----------------------------------------------------------------------------------
--                -- �s�����擾����
--                ----------------------------------------------------------------------------------
--                AND  ((xmril.instruct_qty - xmril.reserved_quantity) > 0
--                  OR  xmril.reserved_quantity IS NULL
--                )
--            ) sub_data
--          GROUP BY
--             sub_data.shipped_cd
--            ,sub_data.item_cd
--        )data
--        ,xxwsh_order_headers_all        xoha    -- 01:�󒍃w�b�_�A�h�I��
--        ,xxwsh_order_lines_all          xola    -- 02:�󒍖��׃A�h�I��
--        ,xxwsh_oe_transaction_types2_v  xottv   -- 03:�󒍃^�C�v���
--        ,xxwsh_tightening_control       xtc     -- 04:�o�׈˗����ߊǗ�(�A�h�I��)
--        ,xxcmn_item_locations2_v        xilv    -- 05:OPM�ۊǏꏊ���
--        ,xxcmn_cust_accounts2_v         xcav    -- 06:�ڋq���(�Ǌ����_)
--        ,xxcmn_cust_acct_sites2_v       xcasv   -- 07:�ڋq�T�C�g���(�o�א�)
--        ,xxcmn_item_mst2_v              ximv    -- 08:OPM�i�ڏ��
--        ,xxinv_mov_lot_details          xmld    -- 09:�ړ����b�g�ڍ�(�A�h�I��)
--        ,ic_lots_mst                    ilm     -- 10:OPM���b�g�}�X�^
--        ,xxcmn_lookup_values2_v         xlvv1   -- 11:�N�C�b�N�R�[�h(�����u���b�N)
--        ,xxcmn_lookup_values2_v         xlvv2   -- 12:�N�C�b�N�R�[�h(�����S���m�F�˗��敪)
--        ,xxcmn_lookup_values2_v         xlvv3   -- 13:�N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
--      WHERE
--        ----------------------------------------------------------------------------------
--        -- �s���i�ڏ��i���ݏ���
--        ----------------------------------------------------------------------------------
--             xoha.deliver_from         =  data.shipped_cd
--        AND  xola.shipping_item_code   =  data.item_cd
--        AND  xoha.schedule_ship_date  >=  TO_DATE(gt_param.shipped_date_from)
--        AND  xoha.schedule_ship_date  <=  TO_DATE(data.shipped_date)
--        AND  (xola.quantity - xola.reserved_quantity) <= 0
--        ----------------------------------------------------------------------------------
--        -- �w�b�_���
--        ----------------------------------------------------------------------------------
--        -- 03:�󒍃^�C�v���
--        AND  xottv.shipping_shikyu_class  =  gc_ship_pro_kbn_s  -- �o�׎x���敪:�o�׈˗�
--        AND  xottv.order_category_code   <>  gc_order_cate_ret  -- �󒍃J�e�S��:�ԕi
--        -- 01:�󒍃w�b�_�A�h�I��
--        AND  xoha.order_type_id           =  xottv.transaction_type_id
--        AND  xoha.req_status             >=  gc_ship_status_close      -- �X�e�[�^�X:���ߍς�
--        AND  xoha.req_status             <>  gc_ship_status_delete     -- �X�e�[�^�X:���
--        AND  xoha.latest_external_flag    =  gc_new_flg                -- �ŐV�t���O
--        -- 04:�o�׈˗����ߊǗ�(�A�h�I��)
--        AND  xoha.tightening_program_id  = xtc.concurrent_id(+)
--        AND  (gt_param.tighten_date IS NULL
--          OR  TRUNC(xtc.tightening_date)  = TRUNC(gt_param.tighten_date)
--        )
--        AND  (xtc.tightening_date IS NULL
--          OR (TO_CHAR(xtc.tightening_date, gc_date_fmt_hm)
--              >= NVL(gt_param.tighten_time_from, gc_time_start)
--            AND  TO_CHAR(xtc.tightening_date, gc_date_fmt_hm)
--              <= NVL(gt_param.tighten_time_to, gc_time_end)
--          )
--        )
--        -- 05:OPM�ۊǏꏊ���
--        AND  xoha.deliver_from_id = xilv.inventory_location_id
--        -- 06:�ڋq���(�Ǌ����_)
--        AND  xoha.head_sales_branch = xcav.party_number
--        -- 07:�ڋq�T�C�g���(�o�א�)
--        AND  xoha.deliver_to_id     = xcasv.party_site_id
--        ----------------------------------------------------------------------------------
--        -- ���׏��
--        ----------------------------------------------------------------------------------
--        -- 02:�󒍖��׃A�h�I��
--        AND  xoha.order_header_id  =  xola.order_header_id
--        AND  xola.delete_flag     <>  gc_delete_flg
--        -- 10:OPM�i�ڏ��
--        AND  xola.shipping_inventory_item_id = ximv.inventory_item_id
--        ----------------------------------------------------------------------------------
--        -- ���b�g���
--        ----------------------------------------------------------------------------------
--        -- 09:�ړ����b�g�ڍ�(�A�h�I��)
--        AND  xola.order_line_id = xmld.mov_line_id
--        AND  xmld.document_type_code = gc_doc_type_ship   -- �����^�C�v:�o�׈˗�
--        AND  xmld.record_type_code   = gc_rec_type_shiji  -- ���R�[�h�^�C�v:�w��
--        -- 10:OPM���b�g�}�X�^
--        AND  xmld.lot_id   =  ilm.lot_id
--        AND  xmld.item_id  =  ilm.item_id
--        ----------------------------------------------------------------------------------
--        -- �N�C�b�N�R�[�h
--        ----------------------------------------------------------------------------------
--        -- 11:�N�C�b�N�R�[�h(�����u���b�N)
--        AND  xlvv1.lookup_type = gc_lookup_cd_block
--        AND  xilv.distribution_block = xlvv1.lookup_code
--        -- 12:�N�C�b�N�R�[�h(�����S���m�F�˗��敪)
--        AND  xlvv2.lookup_type = gc_lookup_cd_conreq
--        AND  xoha.confirm_request_class = xlvv2.lookup_code
--        -- 13:�N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
--        AND  xlvv3.lookup_type = gc_lookup_cd_lot_status
--        AND  ilm.attribute23 = xlvv3.lookup_code
--        ----------------------------------------------------------------------------------
--        -- �K�p��
--        ----------------------------------------------------------------------------------
--        -- 06:�ڋq���(�Ǌ����_)
--        AND  xcav.start_date_active  <= xoha.schedule_ship_date
--        AND  (xcav.end_date_active IS NULL
--          OR  xcav.end_date_active  >= xoha.schedule_ship_date)
--        -- 07:�ڋq�T�C�g���(�o�א�)
--        AND  xcasv.start_date_active <= xoha.schedule_ship_date
--        AND  (xcasv.end_date_active IS NULL
--          OR  xcasv.end_date_active >= xoha.schedule_ship_date)
--        -- 08:OPM�i�ڏ��
--        AND  ximv.start_date_active  <= xoha.schedule_ship_date
--        AND  (ximv.end_date_active IS NULL
--          OR  ximv.end_date_active  >= xoha.schedule_ship_date)
--      ----------------------------------------------------------------------------------
--      -- �s�����擾(�ړ�)
--      ----------------------------------------------------------------------------------
--      UNION ALL
--      SELECT
--        ----------------------------------------------------------------------------------
--        -- �w�b�_���
--        ----------------------------------------------------------------------------------
--         xilv1.distribution_block     AS  block_cd            -- �u���b�N�R�[�h
--        ,xlvv1.meaning                AS  block_nm            -- �u���b�N����
--        ,xmrih.shipped_locat_code     AS  shipped_cd          -- �o�Ɍ��R�[�h
--        ,xilv1.description            AS  shipped_nm          -- �o�Ɍ���
--        ----------------------------------------------------------------------------------
--        -- ���׏��
--        ----------------------------------------------------------------------------------
--        ,xmril.item_code              AS  item_cd             -- �i�ڃR�[�h
--        ,ximv.item_name               AS  item_nm             -- �i�ږ���
--        ,xmrih.schedule_ship_date     AS  shipped_date        -- �o�ɓ�
--        ,xmrih.schedule_arrival_date  AS  arrival_date        -- ����
--        ,TO_CHAR(gc_biz_type_nm_move) AS  biz_type            -- �Ɩ����
--        ,xmrih.mov_num                AS  req_move_no         -- �˗�No/�ړ�No
--        ,NULL                         AS  base_cd             -- �Ǌ����_
--        ,NULL                         AS  base_nm             -- �Ǌ����_����
--        ,xmrih.ship_to_locat_code     AS  delivery_to_cd      -- �z����/���ɐ�
--        ,xilv2.description            AS  delivery_to_nm      -- �z���於��
--        ,SUBSTRB(xmrih.description, 1, 40) AS  description    -- �E�v
--        ,NULL                         AS  conf_req            -- �m�F�˗�
--        ,CASE
--          WHEN xmril.warning_date IS NULL THEN xmril.designated_production_date
--          ELSE xmril.warning_date
--         END                          AS  de_prod_date        -- �w�萻����
--        ,NVL(xmril.warning_date, NVL(xmril.designated_production_date, TO_DATE('19000101', 'YYYYMMDD'))) 
--                                      AS  de_prod_date_sort   -- �w�萻����(�\�[�g�p) 2008/09/26 H.Itou Add T_TE080_BPO_600�w�E38�Ή�
--        ,NULL                         AS  prod_date           -- ������
--        ,NULL                         AS  best_before_date    -- �ܖ�����
--        ,NULL                         AS  native_sign         -- �ŗL�L��
--        ,NULL                         AS  lot_no              -- ���b�gNo
--        ,NULL                         AS  lot_status          -- �i��
---- 2008/09/26 H.Itou Mod Start T_TE080_BPO_600�w�E37�Ή�
----        ,TO_NUMBER(0)                 AS  req_qty             -- �˗���
--        ,CASE 
--           WHEN ximv.conv_unit IS NULL THEN xmril.instruct_qty 
--           ELSE                            (xmril.instruct_qty / ximv.num_of_cases) 
--         END                          AS  req_qty '                 -- �˗��� 2008/09/26 H.Itou Mod T_TE080_BPO_600�w�E37�Ή�
---- 2008/09/26 H.Itou Mod End
--        ,CASE
--          WHEN ximv.conv_unit IS NULL THEN
--            (xmril.instruct_qty - NVL(xmril.reserved_quantity, 0))
--          ELSE ((xmril.instruct_qty - NVL(xmril.reserved_quantity, 0))
--                / TO_NUMBER(
--                    CASE
--                      WHEN ximv.num_of_cases > 0 THEN  ximv.num_of_cases
--                      ELSE TO_CHAR(1)
--                    END)
--          )
--         END                          AS  ins_qty             -- �s����
--        ,NULL                         AS  reserve_order       -- ������
--        ,xmrih.arrival_time_from      AS  time_from           -- ���Ԏw��From
--      FROM
--         xxinv_mov_req_instr_headers    xmrih     -- 01:�ړ��˗�/�w���w�b�_�i�A�h�I���j
--        ,xxinv_mov_req_instr_lines      xmril     -- 02:�ړ��˗�/�w�����ׁi�A�h�I���j
--        ,xxcmn_item_locations2_v        xilv1     -- 03:OPM�ۊǏꏊ���(�o�Ɍ�)
--        ,xxcmn_item_locations2_v        xilv2     -- 04:OPM�ۊǏꏊ���(���ɐ�)
--        ,xxcmn_item_mst2_v              ximv      -- 05:OPM�i�ڏ��
--        ,xxcmn_lookup_values2_v         xlvv1     -- 06:�N�C�b�N�R�[�h(�����u���b�N)
--      WHERE
--        ----------------------------------------------------------------------------------
--        -- �w�b�_���
--        ----------------------------------------------------------------------------------
--        -- 01:�ړ��˗�/�w���w�b�_�i�A�h�I���j
--             xmrih.status               >=  gc_move_status_ordered  -- �X�e�[�^�X:�˗���
--        AND  xmrih.mov_type             <>  gc_mov_type_not_ship    -- �ړ��^�C�v:�ϑ��Ȃ�
--        AND  xmrih.item_class            =  gv_prod_kbn
--        AND  xmrih.schedule_ship_date   >=  gt_param.shipped_date_from
--        AND  xmrih.schedule_ship_date   <=  gt_param.shipped_date_to
--        -- 03:OPM�ۊǏꏊ���(�o�Ɍ�)
--        AND  xilv1.inventory_location_id = xmrih.shipped_locat_id
--        AND  (
--              xilv1.distribution_block = gt_param.block1
--          OR  xilv1.distribution_block = gt_param.block2
--          OR  xilv1.distribution_block = gt_param.block3
--          OR  xmrih.shipped_locat_code = gt_param.shipped_cd
--          OR  (  gt_param.block1 IS NULL
--            AND  gt_param.block2 IS NULL
--            AND  gt_param.block3 IS NULL
--            AND  gt_param.shipped_cd IS NULL
--          )
--        )
--        -- 04:OPM�ۊǏꏊ���(���ɐ�)
--        AND  xilv2.inventory_location_id = xmrih.ship_to_locat_id
--        ----------------------------------------------------------------------------------
--        -- ���׏��
--        ----------------------------------------------------------------------------------
--        -- 02:�ړ��˗�/�w�����ׁi�A�h�I���j
--        AND  xmrih.mov_hdr_id   =  xmril.mov_hdr_id
--        AND  xmril.delete_flg  <>  gc_delete_flg
--        AND  (gt_param.item_cd IS NULL
--          OR  xmril.item_code = gt_param.item_cd
--        )
--        -- 05:OPM�i�ڏ��
--        AND  xmril.item_id = ximv.item_id
--        ----------------------------------------------------------------------------------
--        -- �s�����擾����
--        ----------------------------------------------------------------------------------
--        AND  ((xmril.instruct_qty - xmril.reserved_quantity) > 0
--          OR  xmril.reserved_quantity IS NULL
--        )
--        ----------------------------------------------------------------------------------
--        -- �N�C�b�N�R�[�h
--        ----------------------------------------------------------------------------------
--        -- 06:�N�C�b�N�R�[�h(�����u���b�N)
--        AND  xlvv1.lookup_type = gc_lookup_cd_block
--        AND  xilv1.distribution_block = xlvv1.lookup_code
--        ----------------------------------------------------------------------------------
--        -- �K�p��
--        ----------------------------------------------------------------------------------
--        -- 05:OPM�i�ڏ��
--        AND  ximv.start_date_active  <= xmrih.schedule_ship_date
--        AND  (ximv.end_date_active IS NULL
--          OR  ximv.end_date_active  >= xmrih.schedule_ship_date)
--      ----------------------------------------------------------------------------------
--      -- �s���������̎擾(�ړ�)
--      ----------------------------------------------------------------------------------
--      UNION ALL
--      SELECT
--        ----------------------------------------------------------------------------------
--        -- �w�b�_���
--        ----------------------------------------------------------------------------------
--         xilv1.distribution_block     AS  block_cd            -- �u���b�N�R�[�h
--        ,xlvv1.meaning                AS  block_nm            -- �u���b�N����
--        ,xmrih.shipped_locat_code     AS  shipped_cd          -- �o�Ɍ��R�[�h
--        ,xilv1.description            AS  shipped_nm          -- �o�Ɍ���
--        ----------------------------------------------------------------------------------
--        -- ���׏��
--        ----------------------------------------------------------------------------------
--        ,xmril.item_code              AS  item_cd             -- �i�ڃR�[�h
--        ,ximv.item_name               AS  item_nm             -- �i�ږ���
--        ,xmrih.schedule_ship_date     AS  shipped_date        -- �o�ɓ�
--        ,xmrih.schedule_arrival_date  AS  arrival_date        -- ����
--        ,TO_CHAR(gc_biz_type_nm_move) AS  biz_type            -- �Ɩ����
--        ,xmrih.mov_num                AS  req_move_no         -- �˗�No/�ړ�No
--        ,NULL                         AS  base_cd             -- �Ǌ����_
--        ,NULL                         AS  base_nm             -- �Ǌ����_����
--        ,xmrih.ship_to_locat_code     AS  delivery_to_cd      -- �z����/���ɐ�
--        ,xilv2.description            AS  delivery_to_nm      -- �z���於��
--        ,SUBSTRB(xmrih.description, 1, 40) AS  description    -- �E�v
--        ,NULL                         AS  conf_req            -- �m�F�˗�
--        ,CASE
--          WHEN xmril.warning_date IS NULL THEN xmril.designated_production_date
--          ELSE xmril.warning_date
--         END                          AS  de_prod_date        -- �w�萻����
--        ,NVL(xmril.warning_date, NVL(xmril.designated_production_date, TO_DATE('19000101', 'YYYYMMDD'))) 
--                                      AS  de_prod_date_sort   -- �w�萻����(�\�[�g�p) 2008/09/26 H.Itou Add T_TE080_BPO_600�w�E38�Ή�
--        ,ilm.attribute1               AS  prod_date           -- ������
--        ,ilm.attribute3               AS  best_before_date    -- �ܖ�����
--        ,ilm.attribute2               AS  native_sign         -- �ŗL�L��
--        ,xmld.lot_no                  AS  lot_no              -- ���b�gNo
--        ,xlvv2.meaning                AS  lot_status          -- �i��
--        ,CASE
--          WHEN ximv.conv_unit IS NULL THEN xmld.actual_quantity
--          ELSE (xmld.actual_quantity / TO_NUMBER(
--                                         CASE
--                                           WHEN ximv.num_of_cases > 0 THEN  ximv.num_of_cases
--                                           ELSE TO_CHAR(1)
--                                         END)
--          )
--         END                          AS  req_qty             -- �˗���
--        ,TO_NUMBER(0)                 AS  ins_qty             -- �s����
--        ,NULL                         AS  reserve_order       -- ������
--        ,xmrih.arrival_time_from      AS  time_from           -- ���Ԏw��From
--      FROM
--        (
--          ----------------------------------------------------------------------------------
--          -- �����ϕ��𒊏o���邽�߂̕s���i�ڂ̎擾�i�o�ׁj
--          ----------------------------------------------------------------------------------
--          SELECT
--             sub_data.shipped_cd         AS  shipped_cd    -- �o�׌��ۊǏꏊ
--            ,sub_data.item_cd            AS  item_cd       -- �o�וi��
--            ,MAX(sub_data.shipped_date)  AS  shipped_date  -- �o�ח\���
--          FROM
--            (
--              ----------------------------------------------------------------------------------
--              -- �����ϕ��𒊏o���邽�߂̕s���i�ڂ̎擾�i�o�ׁj
--              ----------------------------------------------------------------------------------
--              SELECT
--                 xoha.deliver_from             AS  shipped_cd    -- �o�׌��ۊǏꏊ
--                ,xola.shipping_item_code       AS  item_cd       -- �o�וi��
--                ,xoha.schedule_ship_date       AS  shipped_date
--              FROM
--                 xxwsh_order_headers_all        xoha    -- 01:�󒍃w�b�_�A�h�I��
--                ,xxwsh_order_lines_all          xola    -- 02:�󒍖��׃A�h�I��
--                ,xxwsh_oe_transaction_types2_v  xottv   -- 03:�󒍃^�C�v���
--                ,xxwsh_tightening_control       xtc     -- 04:�o�׈˗����ߊǗ�(�A�h�I��)
--                ,xxcmn_item_locations2_v        xilv    -- 05:OPM�ۊǏꏊ���
--              WHERE
--                ----------------------------------------------------------------------------------
--                -- �w�b�_���
--                ----------------------------------------------------------------------------------
--                -- 01:�󒍃w�b�_�A�h�I��
--                     xoha.order_type_id       = xottv.transaction_type_id
--                AND  xoha.schedule_ship_date >= gt_param.shipped_date_from
--                AND  xoha.schedule_ship_date <= gt_param.shipped_date_to
--                AND  xoha.latest_external_flag  =  gc_new_flg       -- �ŐV�t���O
--                -- 04:�o�׈˗����ߊǗ�(�A�h�I��)
--                AND  xoha.tightening_program_id  = xtc.concurrent_id(+)
--                AND  (gt_param.tighten_date IS NULL
--                  OR  TRUNC(xtc.tightening_date)  = TRUNC(gt_param.tighten_date)
--                )
--                AND  (xtc.tightening_date IS NULL
--                  OR (TO_CHAR(xtc.tightening_date, gc_date_fmt_hm)
--                      >= NVL(gt_param.tighten_time_from, gc_time_start)
--                    AND  TO_CHAR(xtc.tightening_date, gc_date_fmt_hm)
--                      <= NVL(gt_param.tighten_time_to, gc_time_end)
--                  )
--                )
--                -- 05:OPM�ۊǏꏊ���
--                AND  xoha.deliver_from_id = xilv.inventory_location_id
--                AND  (
--                      xilv.distribution_block = gt_param.block1
--                  OR  xilv.distribution_block = gt_param.block2
--                  OR  xilv.distribution_block = gt_param.block3
--                  OR  xoha.deliver_from = gt_param.shipped_cd
--                  OR  ( gt_param.block1 IS NULL
--                    AND gt_param.block2 IS NULL
--                    AND gt_param.block3 IS NULL
--                    AND gt_param.shipped_cd IS NULL
--                  )
--                )
--                ----------------------------------------------------------------------------------
--                -- ���׏��
--                ----------------------------------------------------------------------------------
--                -- 02:�󒍖��׃A�h�I��
--                AND  xoha.order_header_id = xola.order_header_id
--                AND  xola.delete_flag    <>  gc_delete_flg
--                -- 10:OPM�i�ڏ��
--                AND  (gt_param.item_cd IS NULL
--                   OR xola.shipping_item_code = gt_param.item_cd
--                )
--                AND  xoha.prod_class = gv_prod_kbn
--                ----------------------------------------------------------------------------------
--                -- �s�����擾����
--                ----------------------------------------------------------------------------------
--                AND  ((xola.quantity - xola.reserved_quantity) > 0
--                   OR xola.reserved_quantity IS NULL
--                )
--                ----------------------------------------------------------------------------------
--                -- �K�p��
--                ----------------------------------------------------------------------------------
--                -- 05:OPM�ۊǏꏊ���
--                AND  xilv.date_from <= xoha.schedule_ship_date
--                AND  (xilv.date_to IS NULL
--                  OR  xilv.date_to >= xoha.schedule_ship_date)
--              ----------------------------------------------------------------------------------
--              -- �����ϕ��𒊏o���邽�߂̕s���i�ڂ̎擾(�ړ�)
--              ----------------------------------------------------------------------------------
--              UNION ALL
--              SELECT
--                 xmrih.shipped_locat_code       AS  shipped_cd   -- �o�Ɍ��ۊǏꏊ
--                ,xmril.item_code                AS  item_cd      -- �i��
--                ,xmrih.schedule_ship_date       AS  shipped_date -- �o�ɗ\���
--              FROM
--                 xxinv_mov_req_instr_headers    xmrih     -- 01:�ړ��˗�/�w���w�b�_�i�A�h�I���j
--                ,xxinv_mov_req_instr_lines      xmril     -- 02:�ړ��˗�/�w�����ׁi�A�h�I���j
--                ,xxcmn_item_locations2_v        xilv1     -- 03:OPM�ۊǏꏊ���(�o�Ɍ�)
--              WHERE
--                ----------------------------------------------------------------------------------
--                -- �w�b�_���
--                ----------------------------------------------------------------------------------
--                -- 01:�ړ��˗�/�w���w�b�_�i�A�h�I���j
--                     xmrih.schedule_ship_date >= gt_param.shipped_date_from
--                AND  xmrih.schedule_ship_date <= gt_param.shipped_date_to
--                -- 03:OPM�ۊǏꏊ���(�o�Ɍ�)
--                AND  xilv1.inventory_location_id = xmrih.shipped_locat_id
--                AND  (
--                      xilv1.distribution_block = gt_param.block1
--                  OR  xilv1.distribution_block = gt_param.block2
--                  OR  xilv1.distribution_block = gt_param.block3
--                  OR  xmrih.shipped_locat_code = gt_param.shipped_cd
--                  OR  (  gt_param.block1 IS NULL
--                    AND  gt_param.block2 IS NULL
--                    AND  gt_param.block3 IS NULL
--                    AND  gt_param.shipped_cd IS NULL
--                  )
--                )
--                ----------------------------------------------------------------------------------
--                -- ���׏��
--                ----------------------------------------------------------------------------------
--                -- 02:�ړ��˗�/�w�����ׁi�A�h�I���j
--                AND  xmrih.mov_hdr_id = xmril.mov_hdr_id
--                AND  xmril.delete_flg  <>  gc_delete_flg
--                AND  (gt_param.item_cd IS NULL
--                  OR  xmril.item_code = gt_param.item_cd
--                )
--                AND  xmrih.item_class = gv_prod_kbn
--                ----------------------------------------------------------------------------------
--                -- �s�����擾����
--                ----------------------------------------------------------------------------------
--                AND  ((xmril.instruct_qty - xmril.reserved_quantity) > 0
--                  OR  xmril.reserved_quantity IS NULL
--                )
--            ) sub_data
--          GROUP BY
--             sub_data.shipped_cd
--            ,sub_data.item_cd
--        ) data
--        ,xxinv_mov_req_instr_headers    xmrih     -- 01:�ړ��˗�/�w���w�b�_�i�A�h�I���j
--        ,xxinv_mov_req_instr_lines      xmril     -- 02:�ړ��˗�/�w�����ׁi�A�h�I���j
--        ,xxcmn_item_locations2_v        xilv1     -- 03:OPM�ۊǏꏊ���(�o�Ɍ�)
--        ,xxcmn_item_locations2_v        xilv2     -- 04:OPM�ۊǏꏊ���(���ɐ�)
--        ,xxcmn_item_mst2_v              ximv      -- 05:OPM�i�ڏ��
--        ,xxinv_mov_lot_details          xmld      -- 06:�ړ����b�g�ڍ�(�A�h�I��)
--        ,ic_lots_mst                    ilm       -- 07:OPM���b�g�}�X�^
--        ,xxcmn_lookup_values2_v         xlvv1     -- 08:�N�C�b�N�R�[�h(�����u���b�N)
--        ,xxcmn_lookup_values2_v         xlvv2     -- 09:�N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
--      WHERE
--        ----------------------------------------------------------------------------------
--        -- �s���i�ڏ��i���ݏ���
--        ----------------------------------------------------------------------------------
--             xmrih.shipped_locat_code   =  data.shipped_cd
--        AND  xmril.item_code            =  data.item_cd
--        AND  xmrih.schedule_ship_date  >=  gt_param.shipped_date_from
--        AND  xmrih.schedule_ship_date  <=  data.shipped_date
--        AND  (xmril.instruct_qty - xmril.reserved_quantity) <= 0
--        ----------------------------------------------------------------------------------
--        -- �w�b�_���
--        ----------------------------------------------------------------------------------
--        -- 01:�ړ��˗�/�w���w�b�_�i�A�h�I���j
--        AND  xmrih.status    >=  gc_move_status_ordered  -- �X�e�[�^�X:�˗���
--        AND  xmrih.mov_type  <>  gc_mov_type_not_ship    -- �ړ��^�C�v:�ϑ��Ȃ�
--        -- 03:OPM�ۊǏꏊ���(�o�Ɍ�)
--        AND  xilv1.inventory_location_id = xmrih.shipped_locat_id
--        -- 04:OPM�ۊǏꏊ���(���ɐ�)
--        AND  xilv2.inventory_location_id = xmrih.ship_to_locat_id
--        ----------------------------------------------------------------------------------
--        -- ���׏��
--        ----------------------------------------------------------------------------------
--        -- 02:�ړ��˗�/�w�����ׁi�A�h�I���j
--        AND  xmrih.mov_hdr_id  =  xmril.mov_hdr_id
--        AND  xmril.delete_flg  <>  gc_delete_flg
--        -- 05:OPM�i�ڏ��
--        AND  xmril.item_id = ximv.item_id
--        ----------------------------------------------------------------------------------
--        -- ���b�g���
--        ----------------------------------------------------------------------------------
--        -- 06:�ړ����b�g�ڍ�(�A�h�I��)
--        AND  xmril.mov_line_id =  xmld.mov_line_id
--        AND  xmril.item_id     =  xmld.item_id
--        AND  xmld.document_type_code = gc_doc_type_move   -- �����^�C�v:�ړ�
--        AND  xmld.record_type_code   = gc_rec_type_shiji  -- ���R�[�h�^�C�v:�w��
--        -- 07:OPM���b�g�}�X�^
--        AND  xmld.lot_id   =  ilm.lot_id
--        AND  xmld.item_id  =  ilm.item_id
--        ----------------------------------------------------------------------------------
--        -- �N�C�b�N�R�[�h
--        ----------------------------------------------------------------------------------
--        -- 08:�N�C�b�N�R�[�h(�����u���b�N)
--        AND  xlvv1.lookup_type = gc_lookup_cd_block
--        AND  xilv1.distribution_block = xlvv1.lookup_code
--        -- 09:�N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
--        AND  xlvv2.lookup_type = gc_lookup_cd_lot_status
--        AND  ilm.attribute23 = xlvv2.lookup_code
--        ----------------------------------------------------------------------------------
--        -- �K�p��
--        ----------------------------------------------------------------------------------
--        -- 05:OPM�i�ڏ��
--        AND  ximv.start_date_active  <= xmrih.schedule_ship_date
--        AND  (ximv.end_date_active IS NULL
--          OR  ximv.end_date_active  >= xmrih.schedule_ship_date)
--      ORDER BY
--         block_cd       ASC      -- 01:�u���b�N
--        ,shipped_cd     ASC      -- 02:�o�Ɍ�
--        ,item_cd        ASC      -- 03:�i��
--        ,shipped_date   ASC      -- 04:�o�ɓ�
--        ,arrival_date   ASC      -- 05:����
----        ,de_prod_date   DESC     -- 06:�w�萻����
--        ,de_prod_date_sort   DESC     -- 06:�w�萻���� 2008/09/26 H.Itou Add T_TE080_BPO_600�w�E38�Ή�
--        ,reserve_order  ASC      -- 07:������
--        ,base_cd        ASC      -- 08:�Ǌ����_
--        ,time_from      ASC      -- 09:���Ԏw��From
--        ,req_move_no    ASC      -- 10:�˗�No/�ړ�No
--        ,lot_no         ASC      -- 11:���b�gNo
--      ;
-- 2008/09/26 H.Itou Del End T_S_533(PT�Ή�)
-- 2008/09/26 H.Itou Add Start T_S_533(PT�Ή�)
    -- ===============================
    -- �萔�錾
    -- ===============================
    cv_union_all                   CONSTANT VARCHAR2(32767) := ' UNION ALL ';
--
    -- ===============================
    -- �^�錾
    -- ===============================
    TYPE ref_cursor                IS REF CURSOR ; -- �J�[�\���^
--
    -- ===============================
    -- �ϐ��錾
    -- ===============================
    -- ���ISQL�p�ϐ�
    lv_sql_wsh_short_stock         VARCHAR2(32767); -- �s�����擾(�o��)��SQL
    lv_sql_wsh_stock               VARCHAR2(32767); -- �s���������̎擾(�o��)��SQL
    lv_sql_inv_short_stock         VARCHAR2(32767); -- �s�����擾(�ړ�)��SQL
    lv_sql_inv_stock               VARCHAR2(32767); -- �s���������̎擾(�ړ�)��SQL
    lv_sql_item_short_stock        VARCHAR2(32767); -- �����ϕ��𒊏o���邽�߂̕s���i�ڎ擾��SQL
    lv_where_block_or_deliver_from VARCHAR2(32767); -- ���I�����F�����u���b�N�E�o�Ɍ�����
    lv_where_tightening_date       VARCHAR2(32767); -- ���I�����F���ߎ��{������
    lv_where_item_no               VARCHAR2(32767); -- ���I�����F�i�ڏ���
    lv_sql                         VARCHAR2(32767); -- �SSQL
    lv_order_by                    VARCHAR2(32767); -- ORDER BY
--
    cur_data                       ref_cursor ;    -- �J�[�\��
--
-- 2008/09/26 H.Itou Add End T_S_533(PT�Ή�)
-- 2009/01/14 v1.8 ADD START
--
    -- ���[�f�[�^�p�ϐ�
    lt_report_data       list_report_data ;                                 -- �o�̓f�[�^�i���[�N�j
    lv_block_cd          xilv.distribution_block%TYPE DEFAULT NULL ;        -- �O�񃌃R�[�h�i�[�p�i�u���b�N�R�[�h�j
    lv_tmp_shipped_cd    type_report_data.shipped_cd%TYPE DEFAULT NULL ;    -- �O�񃌃R�[�h�i�[�p�i�o�Ɍ��R�[�h�j
    lv_tmp_item_cd       type_report_data.item_cd%TYPE DEFAULT NULL ;       -- �O�񃌃R�[�h�i�[�p�i�i�ڃR�[�h�j
    ln_report_data_fr    NUMBER DEFAULT 0;                                  -- �����[�f�[�^�̊i�[�p�ԍ��i���j
    ln_report_data_to    NUMBER DEFAULT 0;                                  -- �����[�f�[�^�̊i�[�p�ԍ��i���j
    ln_ins_qty           NUMBER DEFAULT 0;                                  -- �s�����̏W�v�l
    ln_report_data_cnt   NUMBER DEFAULT 0;                                  -- �o�̓f�[�^�i���[�N�j�p�z��J�E���^
-- 2009/01/14 v1.8 ADD END
-- 2009/01/20 v1.9 ADD START
    lv_req_move_no       xoha.request_no%TYPE DEFAULT NULL ;                -- �˗�No/�ړ�No
-- 2009/01/20 v1.9 ADD END
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �S���ҏ��擾
    -- ====================================================
    -- �S������
    gv_dept_cd := SUBSTRB(xxcmn_common_pkg.get_user_dept(gv_user_id), 1, 10) ;
    -- �S����
    gv_dept_nm := SUBSTRB(xxcmn_common_pkg.get_user_name(gv_user_id), 1, 14) ;
--
-- 2008/09/26 H.Itou Del START T_S_533(PT�Ή�)
--    -- ====================================================
--    -- ���[�f�[�^�擾
--    -- ====================================================
--    OPEN cur_data ;
--    FETCH cur_data BULK COLLECT INTO gt_report_data ;
--    CLOSE cur_data ;
-- 2008/09/26 H.Itou Del END T_S_533(PT�Ή�)
--
-- 2008/09/26 H.Itou Add START T_S_533(PT�Ή�)
    -- ========================
    -- ���ߎ��{�������ݒ�
    -- ========================
    -- ���ߎ��{���Ɏw�肠��̏ꍇ
    IF (gt_param.tighten_date IS NOT NULL) THEN
     lv_where_tightening_date := 
        ' AND  TRUNC(xtc.tightening_date)  = TRUNC(:tighten_date) ';
    --
    -- ���ߎ��{���Ɏw��Ȃ��̏ꍇ
    ELSE
     lv_where_tightening_date := 
        ' AND  :tighten_date IS NULL ';
    END IF;
--
    -- ========================
    -- �i�ڏ����ݒ�
    -- ========================
    -- �i�ڂɎw�肠��̏ꍇ
    IF (gt_param.item_cd IS NOT NULL) THEN
     lv_where_item_no := 
        ' AND ximv.item_no = :item_cd ';
--
    -- �i�ڂɎw��Ȃ��̏ꍇ
    ELSE
     lv_where_item_no := 
        ' AND  :item_cd IS NULL ';
    END IF;
--
    -- ===============================
    -- �����u���b�N�E�o�Ɍ������ݒ�
    -- ==============================
    -- �o�Ɍ��E�����u���b�N1�E2�E3���Âꂩ�Ɏw�肪����ꍇ
    IF  ((gt_param.shipped_cd IS NOT NULL) 
      OR (gt_param.block1     IS NOT NULL)
      OR (gt_param.block2     IS NOT NULL)
      OR (gt_param.block3     IS NOT NULL)) THEN
--
      lv_where_block_or_deliver_from := 
         ' AND ((xilv.segment1           = :shipped_cd) '
      || '  OR  (xilv.distribution_block = :block1) '
      || '  OR  (xilv.distribution_block = :block2) '
      || '  OR  (xilv.distribution_block = :block3)) '
      ;
--
    -- �o�Ɍ��E�����u���b�N1�E2�E3���ׂĎw��Ȃ��̏ꍇ
    ELSE
--
      lv_where_block_or_deliver_from := 
         ' AND :shipped_cd IS NULL '
      || ' AND :block1 IS NULL '
      || ' AND :block2 IS NULL '
      || ' AND :block3 IS NULL '
      ;
    END IF;
--
    -- ===========================================================================================
    -- �����ϕ��𒊏o���邽�߂̕s���i�ڂ̎擾(�s��������(�o��),�s��������(�ړ�)��SQL�̃T�u�N�G��
    -- ===========================================================================================
    lv_sql_item_short_stock :=
         ----------------------------------------------------------------------------------
         -- �����ϕ��𒊏o���邽�߂̕s���i�ڂ̎擾
         ----------------------------------------------------------------------------------
       ' SELECT '
    || '   sub_data.shipped_cd         AS  shipped_cd '   -- �o�׌��ۊǏꏊ(�o�Ɍ��ۊǏꏊ)
    || '  ,sub_data.item_cd            AS  item_cd '      -- �o�וi��(�i��)
    || '  ,MAX(sub_data.shipped_date)  AS  shipped_date ' -- �o�ח\���(�o�ɗ\���)
    || ' FROM '
    || '  ( '
           ----------------------------------------------------------------------------------
           -- �����ϕ��𒊏o���邽�߂̕s���i�ڂ̎擾(�o��)
           ----------------------------------------------------------------------------------
    || '   SELECT '
-- 2008/12/10 Miyata Add Start �{��#637 �p�t�H�[�}���X���P
    || '/*+ INDEX ( xtc xxwsh_tico_n02 ) INDEX ( xottv oe_transaction_types_all_u1 ) INDEX ( xilv mtl_item_locations_u1 ) */'
-- 2008/12/10 Miyata Add End �{��#637
    || '     xoha.deliver_from             AS  shipped_cd '   -- �o�׌��ۊǏꏊ
    || '    ,xola.shipping_item_code       AS  item_cd '      -- �o�וi��
    || '    ,xoha.schedule_ship_date       AS  shipped_date ' -- �o�ח\���
    || '   FROM '
    || '     xxwsh_order_headers_all        xoha '   -- 01:�󒍃w�b�_�A�h�I��
    || '    ,xxwsh_order_lines_all          xola '   -- 02:�󒍖��׃A�h�I��
    || '    ,xxwsh_oe_transaction_types2_v  xottv '  -- 03:�󒍃^�C�v���
    || '    ,xxwsh_tightening_control       xtc '    -- 04:�o�׈˗����ߊǗ�(�A�h�I��)
    || '    ,xxcmn_item_locations2_v        xilv '   -- 05:OPM�ۊǏꏊ���
    || '    ,xxcmn_item_mst_v               ximv '   -- 06:OPM�i�ڏ��
    || '   WHERE '
           ----------------------------------------------------------------------------------
           -- �w�b�_���
           ----------------------------------------------------------------------------------
           -- 01:�󒍃w�b�_�A�h�I��
    || '        xoha.order_type_id       = xottv.transaction_type_id '
    || '   AND  xoha.schedule_ship_date >= TO_DATE(:shipped_date_from) '
    || '   AND  xoha.schedule_ship_date <= TO_DATE(:shipped_date_to) '
    || '   AND  xoha.latest_external_flag  = ''' || gc_new_flg || ''' '   -- �ŐV�t���O
-- 2008/12/10 H.Itou Add Start
    || '   AND  xoha.notif_status  <> ''' || gc_notif_status_ktz || ''' '   -- �ʒm�X�e�[�^�X���m��ʒm�ςłȂ�����
-- 2008/12/10 H.Itou Add End
           -- 04:�o�׈˗����ߊǗ�(�A�h�I��)
    || '   AND  xoha.tightening_program_id  = xtc.concurrent_id(+) '
    || '   AND   ((xtc.tightening_date IS NULL) '
    || '     OR   ((TO_CHAR(xtc.tightening_date, ''' || gc_date_fmt_hm || ''')  >= :tighten_time_from) '
    || '       AND (TO_CHAR(xtc.tightening_date, ''' || gc_date_fmt_hm || ''')  <= :tighten_time_to ))) '
           -- 05:OPM�ۊǏꏊ���
    || '   AND  xoha.deliver_from_id = xilv.inventory_location_id '
           ----------------------------------------------------------------------------------
           -- ���׏��
           ----------------------------------------------------------------------------------
           -- 02:�󒍖��׃A�h�I��
    || '   AND  xoha.order_header_id = xola.order_header_id '
    || '   AND  xola.delete_flag    <> ''' || gc_delete_flg || ''' '
           -- 06:OPM�i�ڏ��
    || '   AND  xola.shipping_inventory_item_id = ximv.inventory_item_id '
    || '   AND  xoha.prod_class = ''' || gv_prod_kbn || ''' '
           ----------------------------------------------------------------------------------
           -- �s�����擾����
           ----------------------------------------------------------------------------------
    || '   AND (((xola.quantity - xola.reserved_quantity) > 0) '
    || '     OR  (xola.reserved_quantity IS NULL)) '
           ----------------------------------------------------------------------------------
           -- �K�p������
           ----------------------------------------------------------------------------------
           -- 04:�o�׈˗����ߊǗ�(�A�h�I��)
    || '   AND  xottv.start_date_active <= xoha.schedule_ship_date '
    || '   AND  ((xottv.end_date_active IS NULL) '
    || '     OR  (xottv.end_date_active >= xoha.schedule_ship_date)) '
           -- 05:OPM�ۊǏꏊ
    || '   AND  xilv.date_from <= xoha.schedule_ship_date '
    || '   AND  ((xilv.date_to IS NULL) '
    || '     OR  (xilv.date_to >= xoha.schedule_ship_date)) '
           ----------------------------------------------------------------------------------
           -- ���I����
           ----------------------------------------------------------------------------------
    ||     lv_where_tightening_date       -- ���ߎ��{������
    ||     lv_where_item_no               -- �i�ڏ���
    ||     lv_where_block_or_deliver_from -- �����u���b�N�E�o�Ɍ�����
           ----------------------------------------------------------------------------------
           -- �����ϕ��𒊏o���邽�߂̕s���i�ڂ̎擾(�ړ�)
           ----------------------------------------------------------------------------------
    || '   UNION ALL '
    || '   SELECT '
-- 2008/12/10 Miyata Add Start �{��#637 �p�t�H�[�}���X���P
    || '/*+ INDEX ( xilv mtl_item_locations_u1 ) */'
-- 2008/12/10 Miyata Add End �{��#637
    || '     xmrih.shipped_locat_code       AS  shipped_cd '  -- �o�Ɍ��ۊǏꏊ
    || '    ,xmril.item_code                AS  item_cd '     -- �i��
    || '    ,xmrih.schedule_ship_date       AS  shipped_date '-- �o�ɗ\���
    || '   FROM '
    || '     xxinv_mov_req_instr_headers    xmrih '    -- 01:�ړ��˗�/�w���w�b�_�i�A�h�I���j
    || '    ,xxinv_mov_req_instr_lines      xmril '    -- 02:�ړ��˗�/�w�����ׁi�A�h�I���j
    || '    ,xxcmn_item_locations2_v        xilv  '    -- 03:OPM�ۊǏꏊ���(�o�Ɍ�)
    ||  '   ,xxcmn_item_mst_v               ximv  '    -- 04:OPM�i�ڏ��
    || '   WHERE '
           ----------------------------------------------------------------------------------
           -- �w�b�_���
           ----------------------------------------------------------------------------------
           -- 01:�ړ��˗�/�w���w�b�_�i�A�h�I���j
    || '        xmrih.schedule_ship_date >= TO_DATE(:shipped_date_from) '
    || '   AND  xmrih.schedule_ship_date <= TO_DATE(:shipped_date_to) '
-- 2009/01/07 v1.7 UPDATE START
/*
-- 2008/12/10 H.Itou Add Start
    || '   AND  xmrih.notif_status  <> ''' || gc_notif_status_ktz || ''' '   -- �ʒm�X�e�[�^�X���m��ʒm�ςłȂ�����
-- 2008/12/10 H.Itou Add End
*/
    || '   AND  xmrih.notif_status IN ( ''' || gc_notif_status_mt || ''',''' || gc_notif_status_sty || ''') '   -- �ʒm�X�e�[�^�X���m��ʒm�ςłȂ�����
-- 2009/01/07 v1.7 UPDATE END
           -- 03:OPM�ۊǏꏊ���(�o�Ɍ�)
    || '   AND  xilv.inventory_location_id = xmrih.shipped_locat_id '
           ----------------------------------------------------------------------------------
           -- ���׏��
           ----------------------------------------------------------------------------------
           -- 02:�ړ��˗�/�w�����ׁi�A�h�I���j
    || '   AND  xmrih.mov_hdr_id = xmril.mov_hdr_id '
    || '   AND  xmril.delete_flg  <> ''' || gc_delete_flg || ''' '
    || '   AND  xmrih.item_class   = ''' || gv_prod_kbn || ''' '
           -- 04:OPM�i�ڏ��
    || '   AND  xmril.item_id = ximv.item_id '
           ----------------------------------------------------------------------------------
           -- �s�����擾����
           ----------------------------------------------------------------------------------
    || '   AND (((xmril.instruct_qty - xmril.reserved_quantity) > 0) '
    || '     OR  (xmril.reserved_quantity IS NULL)) '
           ----------------------------------------------------------------------------------
           -- �K�p������
           ----------------------------------------------------------------------------------
           -- 04:OPM�ۊǏꏊ
    || '   AND  xilv.date_from <= xmrih.schedule_ship_date '
    || '   AND  ((xilv.date_to IS NULL) '
    || '     OR  (xilv.date_to >= xmrih.schedule_ship_date)) '
           ----------------------------------------------------------------------------------
           -- ���I����
           ----------------------------------------------------------------------------------
    ||     lv_where_item_no               -- �i�ڏ���
    ||     lv_where_block_or_deliver_from -- �����u���b�N�E�o�Ɍ�����
    || '  ) sub_data '
    || ' GROUP BY '
    || '   sub_data.shipped_cd '
    || '  ,sub_data.item_cd '
    ;
--
    -- ======================================
    -- �s�����擾(�o��)SQL�쐬
    -- ======================================
    lv_sql_wsh_short_stock :=
       ' SELECT '
-- 2008/12/10 Miyata Add Start �{��#637 �p�t�H�[�}���X���P
    || '/*+ INDEX ( xtc xxwsh_tico_n02 ) INDEX ( xottv oe_transaction_types_all_u1 ) INDEX ( xilv mtl_item_locations_u1 ) */'
-- 2008/12/10 Miyata Add End �{��#637
         ----------------------------------------------------------------------------------
         -- �w�b�_��
         ----------------------------------------------------------------------------------
    || '   xilv.distribution_block      AS  block_cd '                -- �u���b�N�R�[�h
    || '  ,xlvv1.meaning                AS  block_nm '                -- �u���b�N����
    || '  ,xoha.deliver_from            AS  shipped_cd '              -- �o�Ɍ��R�[�h
    || '  ,xilv.description             AS  shipped_nm '              -- �o�Ɍ���
         ----------------------------------------------------------------------------------
         -- ���ו�
         ----------------------------------------------------------------------------------
    || '  ,xola.shipping_item_code      AS  item_cd '                 -- �i�ڃR�[�h
    || '  ,ximv.item_name               AS  item_nm '                 -- �i�ږ���
    || '  ,xoha.schedule_ship_date      AS  shipped_date '            -- �o�ɓ�
    || '  ,xoha.schedule_arrival_date   AS  arrival_date '            -- ����
    || '  ,TO_CHAR( ''' || gc_biz_type_nm_ship || ''') AS  biz_type ' -- �Ɩ����
    || '  ,xoha.request_no              AS  req_move_no '             -- �˗�No/�ړ�No
    || '  ,xoha.head_sales_branch       AS  base_cd '                 -- �Ǌ����_
    || '  ,xcav.party_short_name        AS  base_nm '                 -- �Ǌ����_����
    || '  ,xoha.deliver_to              AS  delivery_to_cd '          -- �z����/���ɐ�
    || '  ,xcasv.party_site_full_name   AS  delivery_to_nm '          -- �z���於��
    || '  ,SUBSTRB(xoha.shipping_instructions, 1, 40) '
    || '                                AS  description '             -- �E�v
    || '  ,xlvv2.meaning                AS  conf_req '                -- �m�F�˗�
    || '  ,CASE '
    || '     WHEN xola.warning_date IS NULL THEN xola.designated_production_date '
    || '     ELSE xola.warning_date '
    || '   END                          AS  de_prod_date '            -- �w�萻����
    || '  ,NVL(xola.warning_date, NVL(xola.designated_production_date, TO_DATE(''19000101'', ''YYYYMMDD''))) '
    || '                                AS  de_prod_date_sort '       -- �w�萻����(�\�[�g�p) 2008/09/26 H.Itou Add T_TE080_BPO_600�w�E38�Ή�
    || '  ,NULL                         AS  prod_date '               -- ������
    || '  ,NULL                         AS  best_before_date '        -- �ܖ�����
    || '  ,NULL                         AS  native_sign '             -- �ŗL�L��
    || '  ,NULL                         AS  lot_no '                  -- ���b�gNo
    || '  ,NULL                         AS  lot_status '              -- �i��
-- 2008/10/03 H.Itou Mod Start T_TE080_BPO_600�w�E37 �݌ɕs���̏ꍇ�A�˗����ɂ͕s������\��
--    || '  ,CASE '
--    || '     WHEN ximv.conv_unit IS NULL THEN xola.quantity '
--    || '     ELSE                            (xola.quantity / ximv.num_of_cases) '
    || '  ,CASE '
    || '     WHEN ximv.conv_unit IS NULL THEN '
    || '       (xola.quantity - NVL(xola.reserved_quantity, 0)) '
    || '     ELSE ((xola.quantity - NVL(xola.reserved_quantity, 0)) '
    || '            / TO_NUMBER( '
    || '                CASE  '
    || '                  WHEN ximv.num_of_cases > 0 THEN  ximv.num_of_cases '
    || '                  ELSE TO_CHAR(1) '
    || '                END)) '
-- 2008/10/03 H.Itou Mod End
    || '   END                          AS  req_qty '                 -- �˗���
    || '  ,CASE '
    || '     WHEN ximv.conv_unit IS NULL THEN '
    || '       (xola.quantity - NVL(xola.reserved_quantity, 0)) '
    || '     ELSE ((xola.quantity - NVL(xola.reserved_quantity, 0)) '
    || '            / TO_NUMBER( '
    || '                CASE  '
    || '                  WHEN ximv.num_of_cases > 0 THEN  ximv.num_of_cases '
    || '                  ELSE TO_CHAR(1) '
    || '                END)) '
    || '   END                          AS  ins_qty '                 -- �s����
    || '  ,xcav.reserve_order           AS  reserve_order '           -- ������
    || '  ,xoha.arrival_time_from       AS  time_from '               -- ���Ԏw��From
    || ' FROM '
    || '   xxwsh_order_headers_all        xoha   ' -- 01:�󒍃w�b�_�A�h�I��
    || '  ,xxwsh_order_lines_all          xola   ' -- 02:�󒍖��׃A�h�I��
    || '  ,xxwsh_oe_transaction_types2_v  xottv  ' -- 03:�󒍃^�C�v���
    || '  ,xxwsh_tightening_control       xtc    ' -- 04:�o�׈˗����ߊǗ�(�A�h�I��)
    || '  ,xxcmn_item_locations2_v        xilv   ' -- 05:OPM�ۊǏꏊ���
    || '  ,xxcmn_cust_accounts2_v         xcav   ' -- 06:�ڋq���(�Ǌ����_)
    || '  ,xxcmn_cust_acct_sites2_v       xcasv  ' -- 07:�ڋq�T�C�g���(�o�א�)
    || '  ,xxcmn_item_mst2_v              ximv   ' -- 08:OPM�i�ڏ��
    || '  ,xxcmn_lookup_values2_v         xlvv1  ' -- 09:�N�C�b�N�R�[�h(�����u���b�N)
    || '  ,xxcmn_lookup_values2_v         xlvv2  ' -- 10:�N�C�b�N�R�[�h(�����S���m�F�˗��敪)
    || ' WHERE '
         ----------------------------------------------------------------------------------
         -- �w�b�_���
         ----------------------------------------------------------------------------------
         -- 03:�󒍃^�C�v���
    || '      xottv.shipping_shikyu_class  =  ''' || gc_ship_pro_kbn_s || ''' ' -- �o�׎x���敪:�o�׈˗�
    || ' AND  xottv.order_category_code   <>  ''' || gc_order_cate_ret || ''' ' -- �󒍃J�e�S��:�ԕi
         -- 01:�󒍃w�b�_�A�h�I��
    || ' AND  xoha.order_type_id           =  xottv.transaction_type_id '
-- 2009/01/07 v1.7 UPDATE START
--    || ' AND  xoha.req_status             >=  ''' || gc_ship_status_close  || ''' '      -- �X�e�[�^�X:���ߍς�
--    || ' AND  xoha.req_status             <>  ''' || gc_ship_status_delete || ''' '      -- �X�e�[�^�X:���
    || ' AND  xoha.req_status IN ( ''' || gc_ship_status_close || ''',''' || gc_ship_status_confirm || ''') ' -- �X�e�[�^�X:���ߍς�
-- 2009/01/07 v1.7 UPDATE END
    || ' AND  xoha.latest_external_flag    =  ''' || gc_new_flg  || ''' '                -- �ŐV�t���O
    || ' AND  xoha.prod_class              =  ''' || gv_prod_kbn || ''' '
    || ' AND  xoha.schedule_ship_date     >=  :shipped_date_from '
    || ' AND  xoha.schedule_ship_date     <=  :shipped_date_to '
-- 2008/12/10 H.Itou Add Start
    || ' AND  xoha.notif_status  <> ''' || gc_notif_status_ktz || ''' '   -- �ʒm�X�e�[�^�X���m��ʒm�ςłȂ�����
-- 2008/12/10 H.Itou Add End
         -- 04:�o�׈˗����ߊǗ�(�A�h�I��)
    || ' AND  xoha.tightening_program_id  = xtc.concurrent_id(+) '
    || ' AND   ((xtc.tightening_date IS NULL) '
    || '   OR   ((TO_CHAR(xtc.tightening_date, ''' || gc_date_fmt_hm || ''')  >= :tighten_time_from) '
    || '     AND (TO_CHAR(xtc.tightening_date, ''' || gc_date_fmt_hm || ''')  <= :tighten_time_to ))) '
         -- 05:OPM�ۊǏꏊ���
    || ' AND  xoha.deliver_from_id = xilv.inventory_location_id '
         -- 06:�ڋq���(�Ǌ����_)
    || ' AND  xoha.head_sales_branch = xcav.party_number '
         -- 07:�ڋq�T�C�g���(�o�א�)
    || ' AND  xoha.deliver_to_id     = xcasv.party_site_id '
         ----------------------------------------------------------------------------------
         -- ���׏��
         ----------------------------------------------------------------------------------
         -- 02:�󒍖��׃A�h�I��
    || ' AND  xoha.order_header_id =  xola.order_header_id '
    || ' AND  xola.delete_flag    <>  ''' || gc_delete_flg || ''' '
         -- 08:OPM�i�ڏ�� '
    || ' AND  xola.shipping_inventory_item_id = ximv.inventory_item_id '
         ----------------------------------------------------------------------------------
         -- �s�����擾����
         ----------------------------------------------------------------------------------
    || ' AND  (((xola.quantity - xola.reserved_quantity) > 0) '
    || '    OR  (xola.reserved_quantity IS NULL)) '
         ----------------------------------------------------------------------------------
         -- �N�C�b�N�R�[�h
         ----------------------------------------------------------------------------------
         -- 09:�N�C�b�N�R�[�h(�����u���b�N)
    || ' AND  xlvv1.lookup_type = ''' || gc_lookup_cd_block || ''' '
    || ' AND  xilv.distribution_block = xlvv1.lookup_code '
         -- 10:�N�C�b�N�R�[�h(�����S���m�F�˗��敪)
    || ' AND  xlvv2.lookup_type = ''' || gc_lookup_cd_conreq || ''' '
    || ' AND  xoha.confirm_request_class = xlvv2.lookup_code '
         ----------------------------------------------------------------------------------
         -- �K�p��
         ----------------------------------------------------------------------------------
         -- 04:�o�׈˗����ߊǗ�(�A�h�I��)
    || ' AND  xottv.start_date_active <= xoha.schedule_ship_date '
    || ' AND  ((xottv.end_date_active IS NULL) '
    || '   OR  (xottv.end_date_active >= xoha.schedule_ship_date)) '
         -- 05:OPM�ۊǏꏊ
    || ' AND  xilv.date_from <= xoha.schedule_ship_date '
    || ' AND  ((xilv.date_to IS NULL) '
    || '   OR  (xilv.date_to >= xoha.schedule_ship_date)) '
         -- 06:�ڋq���(�Ǌ����_)
    || ' AND  xcav.start_date_active  <= xoha.schedule_ship_date '
    || ' AND ((xcav.end_date_active IS NULL) '
    || '   OR (xcav.end_date_active  >= xoha.schedule_ship_date)) '
         -- 07:�ڋq�T�C�g���(�o�א�)
    || ' AND  xcasv.start_date_active <= xoha.schedule_ship_date '
    || ' AND ((xcasv.end_date_active IS NULL) '
    || '   OR (xcasv.end_date_active >= xoha.schedule_ship_date)) '
         -- 08:OPM�i�ڏ��
    || ' AND  ximv.start_date_active  <= xoha.schedule_ship_date '
    || ' AND ((ximv.end_date_active IS NULL) '
    || '   OR (ximv.end_date_active  >= xoha.schedule_ship_date)) '
         -- 09:�N�C�b�N�R�[�h(�����u���b�N)
    || ' AND  xlvv1.start_date_active  <= xoha.schedule_ship_date '
    || ' AND ((xlvv1.end_date_active IS NULL) '
    || '   OR (xlvv1.end_date_active  >= xoha.schedule_ship_date)) '
         -- 10:�N�C�b�N�R�[�h(�����S���m�F�˗��敪)
    || ' AND  xlvv2.start_date_active  <= xoha.schedule_ship_date '
    || ' AND ((xlvv2.end_date_active IS NULL) '
    || '   OR (xlvv2.end_date_active  >= xoha.schedule_ship_date)) '
         ----------------------------------------------------------------------------------
         -- ���I����
         ----------------------------------------------------------------------------------
    ||   lv_where_tightening_date       -- ���ߎ��{������
    ||   lv_where_item_no               -- �i�ڏ���
    ||   lv_where_block_or_deliver_from -- �����u���b�N�E�o�Ɍ�����
    ;
--
    -- ======================================
    -- �s��������(�o��)SQL�쐬
    -- ======================================
    lv_sql_wsh_stock :=
       ' SELECT '
-- 2008/12/10 Miyata Add Start �{��#637 �p�t�H�[�}���X���P
    || '/*+ INDEX ( xtc xxwsh_tico_n02 ) INDEX ( xottv oe_transaction_types_all_u1 ) INDEX ( xilv mtl_item_locations_u1) */'
-- 2008/12/10 Miyata Add End �{��#637
         ----------------------------------------------------------------------------------
         -- �w�b�_��
         ----------------------------------------------------------------------------------
    || '   xilv.distribution_block      AS  block_cd '           -- �u���b�N�R�[�h
    || '  ,xlvv1.meaning                AS  block_nm '           -- �u���b�N����
    || '  ,xoha.deliver_from            AS  shipped_cd '         -- �o�Ɍ��R�[�h
    || '  ,xilv.description             AS  shipped_nm '         -- �o�Ɍ���
         ----------------------------------------------------------------------------------
         -- ���ו�
         ----------------------------------------------------------------------------------
    || '  ,xola.shipping_item_code      AS  item_cd '            -- �i�ڃR�[�h
    || '  ,ximv.item_name               AS  item_nm '            -- �i�ږ���
    || '  ,xoha.schedule_ship_date      AS  shipped_date '       -- �o�ɓ�
    || '  ,xoha.schedule_arrival_date   AS  arrival_date '       -- ����
    || '  ,TO_CHAR(''' || gc_biz_type_nm_ship || ''') AS  biz_type '           -- �Ɩ����
    || '  ,xoha.request_no              AS  req_move_no '        -- �˗�No/�ړ�No
    || '  ,xoha.head_sales_branch       AS  base_cd '            -- �Ǌ����_
    || '  ,xcav.party_short_name        AS  base_nm '            -- �Ǌ����_����
    || '  ,xoha.deliver_to              AS  delivery_to_cd '     -- �z����/���ɐ�
    || '  ,xcasv.party_site_full_name   AS  delivery_to_nm '     -- �z���於��
    || '  ,SUBSTRB(xoha.shipping_instructions, 1, 40) '
    || '                                AS  description '        -- �E�v
    || '  ,xlvv2.meaning                AS  conf_req '           -- �m�F�˗�
    || '  ,CASE '
    || '     WHEN xola.warning_date IS NULL THEN xola.designated_production_date '
    || '     ELSE xola.warning_date '
    || '   END                          AS  de_prod_date '       -- �w�萻����
    || '  ,NVL(xola.warning_date, NVL(xola.designated_production_date, TO_DATE(''19000101'', ''YYYYMMDD''))) '
    || '                                AS  de_prod_date_sort '  -- �w�萻����(�\�[�g�p) 2008/09/26 H.Itou Add T_TE080_BPO_600�w�E38�Ή�
    || '  ,ilm.attribute1               AS  prod_date '          -- ������
    || '  ,ilm.attribute3               AS  best_before_date '   -- �ܖ�����
    || '  ,ilm.attribute2               AS  native_sign '        -- �ŗL�L��
    || '  ,xmld.lot_no                  AS  lot_no '             -- ���b�gNo
    || '  ,xlvv3.meaning                AS  lot_status '         -- �i��
    || '  ,CASE '
    || '    WHEN ximv.conv_unit IS NULL THEN xmld.actual_quantity '
    || '    ELSE (xmld.actual_quantity '
    || '          / TO_NUMBER( '
    || '              CASE '
    || '                WHEN ximv.num_of_cases > 0 THEN  ximv.num_of_cases '
    || '                ELSE TO_CHAR(1) '
    || '              END)) '
    || '   END                          AS  req_qty '            -- �˗���
    || '  ,TO_NUMBER(0)                 AS  ins_qty '            -- �s����
    || '  ,xcav.reserve_order           AS  reserve_order '      -- ������
    || '  ,xoha.arrival_time_from       AS  time_from '          -- ���Ԏw��From
    || ' FROM '
    || '  ( ' || lv_sql_item_short_stock || ') data '   -- 00:�����ϕ��𒊏o���邽�߂̕s���i�ڂ̃T�u�N�G��
    || '  ,xxwsh_order_headers_all        xoha '   -- 01:�󒍃w�b�_�A�h�I��
    || '  ,xxwsh_order_lines_all          xola '   -- 02:�󒍖��׃A�h�I��
    || '  ,xxwsh_oe_transaction_types2_v  xottv '  -- 03:�󒍃^�C�v���
    || '  ,xxwsh_tightening_control       xtc '    -- 04:�o�׈˗����ߊǗ�(�A�h�I��)
    || '  ,xxcmn_item_locations2_v        xilv '   -- 05:OPM�ۊǏꏊ���
    || '  ,xxcmn_cust_accounts2_v         xcav '   -- 06:�ڋq���(�Ǌ����_)
    || '  ,xxcmn_cust_acct_sites2_v       xcasv '  -- 07:�ڋq�T�C�g���(�o�א�)
    || '  ,xxcmn_item_mst2_v              ximv '   -- 08:OPM�i�ڏ��
    || '  ,xxinv_mov_lot_details          xmld '   -- 09:�ړ����b�g�ڍ�(�A�h�I��)
    || '  ,ic_lots_mst                    ilm '    -- 10:OPM���b�g�}�X�^
    || '  ,xxcmn_lookup_values2_v         xlvv1 '  -- 11:�N�C�b�N�R�[�h(�����u���b�N)
    || '  ,xxcmn_lookup_values2_v         xlvv2 '  -- 12:�N�C�b�N�R�[�h(�����S���m�F�˗��敪)
    || '  ,xxcmn_lookup_values2_v         xlvv3 '  -- 13:�N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
    || ' WHERE '
         ----------------------------------------------------------------------------------
         -- �s���i�ڏ��i���ݏ���
         ----------------------------------------------------------------------------------
    || '       xoha.deliver_from        =  data.shipped_cd '
    || ' AND  xola.shipping_item_code   =  data.item_cd '
    || ' AND  xoha.schedule_ship_date  >=  TO_DATE(:shipped_date_from) '
    || ' AND  xoha.schedule_ship_date  <=  TO_DATE(data.shipped_date) '
-- 2008/10/03 H.Itou Mod Start �����������A�S�����𒊏o�������̂ŁA�s�����ύX
--    || ' AND  (xola.quantity - xola.reserved_quantity) <= 0 '
    || ' AND  (xola.quantity - xola.reserved_quantity) >= 0 '
-- 2008/10/03 H.Itou Del End
         ----------------------------------------------------------------------------------
         -- �w�b�_���
         ----------------------------------------------------------------------------------
         -- 03:�󒍃^�C�v���
    || ' AND  xottv.shipping_shikyu_class  = ''' || gc_ship_pro_kbn_s || ''' '  -- �o�׎x���敪:�o�׈˗�
    || ' AND  xottv.order_category_code   <> ''' || gc_order_cate_ret || ''' '  -- �󒍃J�e�S��:�ԕi
         -- 01:�󒍃w�b�_�A�h�I��
    || ' AND  xoha.order_type_id           =  xottv.transaction_type_id '
-- 2009/01/07 v1.7 UPDATE START
--    || ' AND  xoha.req_status             >= ''' || gc_ship_status_close || ''' '     -- �X�e�[�^�X:���ߍς�
--    || ' AND  xoha.req_status             <> ''' || gc_ship_status_delete || ''' '    -- �X�e�[�^�X:���
    || ' AND  xoha.req_status IN ( ''' || gc_ship_status_close || ''',''' || gc_ship_status_confirm || ''') ' -- �X�e�[�^�X:���ߍς�
-- 2009/01/07 v1.7 UPDATE END
    || ' AND  xoha.latest_external_flag    = ''' || gc_new_flg || ''' '               -- �ŐV�t���O
-- 2008/12/10 H.Itou Add Start
    || ' AND  xoha.notif_status  <> ''' || gc_notif_status_ktz || ''' '   -- �ʒm�X�e�[�^�X���m��ʒm�ςłȂ�����
-- 2008/12/10 H.Itou Add End
         -- 04:�o�׈˗����ߊǗ�(�A�h�I��)
    || ' AND  xoha.tightening_program_id  = xtc.concurrent_id(+) '
    || ' AND   ((xtc.tightening_date IS NULL) '
    || '   OR   ((TO_CHAR(xtc.tightening_date, ''' || gc_date_fmt_hm || ''')  >= :tighten_time_from) '
    || '     AND (TO_CHAR(xtc.tightening_date, ''' || gc_date_fmt_hm || ''')  <= :tighten_time_to ))) '
         -- 05:OPM�ۊǏꏊ���
    || ' AND  xoha.deliver_from_id = xilv.inventory_location_id '
         -- 06:�ڋq���(�Ǌ����_)
    || ' AND  xoha.head_sales_branch = xcav.party_number '
         -- 07:�ڋq�T�C�g���(�o�א�)
    || ' AND  xoha.deliver_to_id     = xcasv.party_site_id '
         ----------------------------------------------------------------------------------
         -- ���׏��
         ----------------------------------------------------------------------------------
         -- 02:�󒍖��׃A�h�I��
    || ' AND  xoha.order_header_id  =  xola.order_header_id '
    || ' AND  xola.delete_flag     <> ''' || gc_delete_flg || ''' '
         -- 10:OPM�i�ڏ��
    || ' AND  xola.shipping_inventory_item_id = ximv.inventory_item_id '
         ----------------------------------------------------------------------------------
         -- ���b�g���
         ----------------------------------------------------------------------------------
         -- 09:�ړ����b�g�ڍ�(�A�h�I��)
    || ' AND  xola.order_line_id = xmld.mov_line_id '
    || ' AND  xmld.document_type_code = ''' || gc_doc_type_ship  || ''' '  -- �����^�C�v:�o�׈˗�
    || ' AND  xmld.record_type_code   = ''' || gc_rec_type_shiji || ''' '  -- ���R�[�h�^�C�v:�w��
         -- 10:OPM���b�g�}�X�^
    || ' AND  xmld.lot_id   =  ilm.lot_id '
    || ' AND  xmld.item_id  =  ilm.item_id '
         ----------------------------------------------------------------------------------
         -- �N�C�b�N�R�[�h
         ----------------------------------------------------------------------------------
         -- 11:�N�C�b�N�R�[�h(�����u���b�N)
    || ' AND  xlvv1.lookup_type = ''' || gc_lookup_cd_block || ''' '
    || ' AND  xilv.distribution_block = xlvv1.lookup_code '
         -- 12:�N�C�b�N�R�[�h(�����S���m�F�˗��敪)
    || ' AND  xlvv2.lookup_type = ''' || gc_lookup_cd_conreq || ''' '
    || ' AND  xoha.confirm_request_class = xlvv2.lookup_code '
         -- 13:�N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
    || ' AND  xlvv3.lookup_type = ''' || gc_lookup_cd_lot_status || ''' '
    || ' AND  ilm.attribute23 = xlvv3.lookup_code '
         ----------------------------------------------------------------------------------
         -- �K�p��
         ----------------------------------------------------------------------------------
         -- 04:�o�׈˗����ߊǗ�(�A�h�I��)
    || ' AND  xottv.start_date_active <= xoha.schedule_ship_date '
    || ' AND  ((xottv.end_date_active IS NULL) '
    || '   OR  (xottv.end_date_active >= xoha.schedule_ship_date)) '
         -- 05:OPM�ۊǏꏊ
    || ' AND  xilv.date_from <= xoha.schedule_ship_date '
    || ' AND  ((xilv.date_to IS NULL) '
    || '   OR  (xilv.date_to >= xoha.schedule_ship_date)) '
         -- 06:�ڋq���(�Ǌ����_)
    || ' AND  xcav.start_date_active  <= xoha.schedule_ship_date '
    || ' AND ((xcav.end_date_active IS NULL) '
    || '   OR (xcav.end_date_active  >= xoha.schedule_ship_date)) '
         -- 07:�ڋq�T�C�g���(�o�א�)
    || ' AND  xcasv.start_date_active <= xoha.schedule_ship_date '
    || ' AND ((xcasv.end_date_active IS NULL) '
    || '   OR (xcasv.end_date_active >= xoha.schedule_ship_date)) '
         -- 08:OPM�i�ڏ��
    || ' AND  ximv.start_date_active  <= xoha.schedule_ship_date '
    || ' AND ((ximv.end_date_active IS NULL) '
    || '   OR (ximv.end_date_active  >= xoha.schedule_ship_date)) '
         -- 11:�N�C�b�N�R�[�h(�����u���b�N)
    || ' AND  xlvv1.start_date_active  <= xoha.schedule_ship_date '
    || ' AND ((xlvv1.end_date_active IS NULL) '
    || '   OR (xlvv1.end_date_active  >= xoha.schedule_ship_date)) '
         -- 12:�N�C�b�N�R�[�h(�����S���m�F�˗��敪)
    || ' AND  xlvv2.start_date_active  <= xoha.schedule_ship_date '
    || ' AND ((xlvv2.end_date_active IS NULL) '
    || '   OR (xlvv2.end_date_active  >= xoha.schedule_ship_date)) '
         -- 13:�N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
    || ' AND  xlvv3.start_date_active  <= xoha.schedule_ship_date '
    || ' AND ((xlvv3.end_date_active IS NULL) '
    || '   OR (xlvv3.end_date_active  >= xoha.schedule_ship_date)) '
         ----------------------------------------------------------------------------------
         -- ���I����
         ----------------------------------------------------------------------------------
    ||   lv_where_tightening_date       -- ���ߎ��{������
    ;
    -- ======================================
    -- �s�����擾(�ړ�)
    -- ======================================
    lv_sql_inv_short_stock :=
       ' SELECT '
-- 2008/12/10 Miyata Add Start �{��#637 �p�t�H�[�}���X���P
    || '/*+ INDEX ( xilv mtl_item_locations_u1 ) INDEX (xilv2 mtl_item_locations_u1 ) */'
-- 2008/12/10 Miyata Add End �{��#637
         ----------------------------------------------------------------------------------
         -- �w�b�_���
         ----------------------------------------------------------------------------------
    || '   xilv.distribution_block      AS  block_cd '           -- �u���b�N�R�[�h
    || '  ,xlvv1.meaning                AS  block_nm '           -- �u���b�N����
    || '  ,xmrih.shipped_locat_code     AS  shipped_cd '         -- �o�Ɍ��R�[�h
    || '  ,xilv.description             AS  shipped_nm '         -- �o�Ɍ���
         ----------------------------------------------------------------------------------
         -- ���׏��
         ----------------------------------------------------------------------------------
    || '  ,xmril.item_code              AS  item_cd '            -- �i�ڃR�[�h
    || '  ,ximv.item_name               AS  item_nm '            -- �i�ږ���
    || '  ,xmrih.schedule_ship_date     AS  shipped_date '       -- �o�ɓ�
    || '  ,xmrih.schedule_arrival_date  AS  arrival_date '       -- ����
    || '  ,TO_CHAR(''' || gc_biz_type_nm_move || ''') AS  biz_type '           -- �Ɩ����
    || '  ,xmrih.mov_num                AS  req_move_no '        -- �˗�No/�ړ�No
    || '  ,NULL                         AS  base_cd '            -- �Ǌ����_
    || '  ,NULL                         AS  base_nm '            -- �Ǌ����_����
    || '  ,xmrih.ship_to_locat_code     AS  delivery_to_cd '     -- �z����/���ɐ�
    || '  ,xilv2.description            AS  delivery_to_nm '     -- �z���於��
    || '  ,SUBSTRB(xmrih.description, 1, 40) AS  description '   -- �E�v
    || '  ,NULL                         AS  conf_req '           -- �m�F�˗�
    || '  ,CASE '
    || '    WHEN xmril.warning_date IS NULL THEN xmril.designated_production_date '
    || '    ELSE xmril.warning_date '
    || '   END                          AS  de_prod_date '       -- �w�萻����
    || '  ,NVL(xmril.warning_date, NVL(xmril.designated_production_date, TO_DATE(''19000101'', ''YYYYMMDD''))) '
    || '                                AS  de_prod_date_sort '  -- �w�萻����(�\�[�g�p) 2008/09/26 H.Itou Add T_TE080_BPO_600�w�E38�Ή�
    || '  ,NULL                         AS  prod_date '          -- ������
    || '  ,NULL                         AS  best_before_date '   -- �ܖ�����
    || '  ,NULL                         AS  native_sign '        -- �ŗL�L��
    || '  ,NULL                         AS  lot_no '             -- ���b�gNo
    || '  ,NULL                         AS  lot_status '         -- �i��
-- 2008/10/03 H.Itou Mod Start T_TE080_BPO_600�w�E37 �݌ɕs���̏ꍇ�A�˗����ɂ͕s������\��
--    || '  ,CASE '
--    || '     WHEN ximv.conv_unit IS NULL THEN xmril.instruct_qty '
--    || '     ELSE                            (xmril.instruct_qty / ximv.num_of_cases) '
    || '  ,CASE '
    || '    WHEN ximv.conv_unit IS NULL THEN '
    || '      (xmril.instruct_qty - NVL(xmril.reserved_quantity, 0)) '
    || '    ELSE ((xmril.instruct_qty - NVL(xmril.reserved_quantity, 0)) '
    || '          / TO_NUMBER( '
    || '              CASE '
    || '                WHEN ximv.num_of_cases > 0 THEN  ximv.num_of_cases '
    || '                ELSE TO_CHAR(1) '
    || '              END)) '
-- 2008/10/03 H.Itou Mod End
    || '   END                          AS  req_qty '            -- �˗���
    || '  ,CASE '
    || '    WHEN ximv.conv_unit IS NULL THEN '
    || '      (xmril.instruct_qty - NVL(xmril.reserved_quantity, 0)) '
    || '    ELSE ((xmril.instruct_qty - NVL(xmril.reserved_quantity, 0)) '
    || '          / TO_NUMBER( '
    || '              CASE '
    || '                WHEN ximv.num_of_cases > 0 THEN  ximv.num_of_cases '
    || '                ELSE TO_CHAR(1) '
    || '              END)) '
    || '   END                          AS  ins_qty '            -- �s����
    || '  ,NULL                         AS  reserve_order '      -- ������
    || '  ,xmrih.arrival_time_from      AS  time_from '          -- ���Ԏw��From
    || ' FROM '
    || '   xxinv_mov_req_instr_headers    xmrih '    -- 01:�ړ��˗�/�w���w�b�_�i�A�h�I���j
    || '  ,xxinv_mov_req_instr_lines      xmril '    -- 02:�ړ��˗�/�w�����ׁi�A�h�I���j
    || '  ,xxcmn_item_locations2_v        xilv '     -- 03:OPM�ۊǏꏊ���(�o�Ɍ�)
    || '  ,xxcmn_item_locations2_v        xilv2 '    -- 04:OPM�ۊǏꏊ���(���ɐ�)
    || '  ,xxcmn_item_mst2_v              ximv  '    -- 05:OPM�i�ڏ��
    || '  ,xxcmn_lookup_values2_v         xlvv1 '    -- 06:�N�C�b�N�R�[�h(�����u���b�N)
    || ' WHERE '
         ----------------------------------------------------------------------------------
         -- �w�b�_���
         ----------------------------------------------------------------------------------
         -- 01:�ړ��˗�/�w���w�b�_�i�A�h�I���j
    || '      xmrih.status               >=  ''' || gc_move_status_ordered || ''' ' -- �X�e�[�^�X:�˗���
    || ' AND  xmrih.mov_type             <>  ''' || gc_mov_type_not_ship   || ''' '   -- �ړ��^�C�v:�ϑ��Ȃ�
    || ' AND  xmrih.item_class            =  ''' || gv_prod_kbn            || ''' '
    || ' AND  xmrih.schedule_ship_date   >=  :shipped_date_from '
    || ' AND  xmrih.schedule_ship_date   <=  :shipped_date_to '
-- 2009/01/07 v1.7 UPDATE START
/*
-- 2008/12/10 H.Itou Add Start
    || ' AND  xmrih.notif_status  <> ''' || gc_notif_status_ktz || ''' '   -- �ʒm�X�e�[�^�X���m��ʒm�ςłȂ�����
-- 2008/12/10 H.Itou Add End
*/
    || '   AND  xmrih.notif_status IN ( ''' || gc_notif_status_mt || ''',''' || gc_notif_status_sty || ''') '   -- �ʒm�X�e�[�^�X���m��ʒm�ςłȂ�����
-- 2009/01/07 v1.7 UPDATE START
        -- 03:OPM�ۊǏꏊ���(�o�Ɍ�)
    || ' AND  xilv.inventory_location_id = xmrih.shipped_locat_id '
         -- 04:OPM�ۊǏꏊ���(���ɐ�)
    || ' AND  xilv2.inventory_location_id = xmrih.ship_to_locat_id '
         ----------------------------------------------------------------------------------
         -- ���׏��
         ----------------------------------------------------------------------------------
         -- 02:�ړ��˗�/�w�����ׁi�A�h�I���j
    || ' AND  xmrih.mov_hdr_id   =  xmril.mov_hdr_id '
    || ' AND  xmril.delete_flg  <>  ''' || gc_delete_flg || ''' '
         -- 05:OPM�i�ڏ��
    || ' AND  xmril.item_id = ximv.item_id '
         ----------------------------------------------------------------------------------
         -- �s�����擾����
         ----------------------------------------------------------------------------------
    || ' AND (((xmril.instruct_qty - xmril.reserved_quantity) > 0) '
    || '   OR  (xmril.reserved_quantity IS NULL)) '
         ----------------------------------------------------------------------------------
         -- �N�C�b�N�R�[�h
         ----------------------------------------------------------------------------------
         -- 06:�N�C�b�N�R�[�h(�����u���b�N)
    || ' AND  xlvv1.lookup_type = ''' || gc_lookup_cd_block || ''' '
    || ' AND  xilv.distribution_block = xlvv1.lookup_code '
         ----------------------------------------------------------------------------------
         -- �K�p��
         ----------------------------------------------------------------------------------
         -- 03:OPM�ۊǏꏊ(�o�Ɍ�)
    || ' AND  xilv.date_from <= xmrih.schedule_ship_date '
    || ' AND  ((xilv.date_to IS NULL) '
    || '   OR  (xilv.date_to >= xmrih.schedule_ship_date)) '
         -- 04:OPM�ۊǏꏊ(���ɐ�)
    || ' AND  xilv2.date_from <= xmrih.schedule_ship_date '
    || ' AND  ((xilv2.date_to IS NULL) '
    || '   OR  (xilv2.date_to >= xmrih.schedule_ship_date)) '
         -- 05:OPM�i�ڏ��
    || ' AND  ximv.start_date_active  <= xmrih.schedule_ship_date '
    || ' AND ((ximv.end_date_active IS NULL) '
    || '   OR (ximv.end_date_active  >= xmrih.schedule_ship_date)) '
         -- 06:�N�C�b�N�R�[�h(�����u���b�N)
    || ' AND  xlvv1.start_date_active  <= xmrih.schedule_ship_date '
    || ' AND ((xlvv1.end_date_active IS NULL) '
    || '   OR (xlvv1.end_date_active  >= xmrih.schedule_ship_date)) '
-- 2008/11/13 v1.4 T.Yoshimoto Add Start
    || ' AND ((xmrih.no_instr_actual_class <> ''' || gc_move_instr_actual_class || ''') '
    || '   OR (xmrih.no_instr_actual_class IS NULL)) '
-- 2008/11/13 v1.4 T.Yoshimoto Add End

         ----------------------------------------------------------------------------------
         -- ���I����
         ----------------------------------------------------------------------------------
    ||   lv_where_item_no               -- �i�ڏ���
    ||   lv_where_block_or_deliver_from -- �����u���b�N�E�o�Ɍ�����
    ;
--
    -- ======================================
    -- �s���������̎擾(�ړ�)
    -- ======================================
    lv_sql_inv_stock :=
       ' SELECT '
-- 2008/12/10 Miyata Add Start �{��#637 �p�t�H�[�}���X���P
    || '/*+ INDEX ( xilv1 mtl_item_locations_u1 ) INDEX ( xilv2 mtl_item_locations_u1 ) */'
-- 2008/12/10 Miyata Add End �{��#637
         ----------------------------------------------------------------------------------
         -- �w�b�_���
         ----------------------------------------------------------------------------------
    || '   xilv1.distribution_block     AS  block_cd '           -- �u���b�N�R�[�h
    || '  ,xlvv1.meaning                AS  block_nm '           -- �u���b�N����
    || '  ,xmrih.shipped_locat_code     AS  shipped_cd '         -- �o�Ɍ��R�[�h
    || '  ,xilv1.description            AS  shipped_nm '         -- �o�Ɍ���
         ----------------------------------------------------------------------------------
         -- ���׏��
         ----------------------------------------------------------------------------------
    || '  ,xmril.item_code              AS  item_cd '            -- �i�ڃR�[�h
    || '  ,ximv.item_name               AS  item_nm '            -- �i�ږ���
    || '  ,xmrih.schedule_ship_date     AS  shipped_date '       -- �o�ɓ�
    || '  ,xmrih.schedule_arrival_date  AS  arrival_date '       -- ����
    || '  ,TO_CHAR(''' || gc_biz_type_nm_move || ''') AS  biz_type '           -- �Ɩ����
    || '  ,xmrih.mov_num                AS  req_move_no '        -- �˗�No/�ړ�No
    || '  ,NULL                         AS  base_cd '            -- �Ǌ����_
    || '  ,NULL                         AS  base_nm '            -- �Ǌ����_����
    || '  ,xmrih.ship_to_locat_code     AS  delivery_to_cd '     -- �z����/���ɐ�
    || '  ,xilv2.description            AS  delivery_to_nm '     -- �z���於��
    || '  ,SUBSTRB(xmrih.description, 1, 40) AS  description '   -- �E�v
    || '  ,NULL                         AS  conf_req '           -- �m�F�˗�
    || '  ,CASE '
    || '     WHEN xmril.warning_date IS NULL THEN xmril.designated_production_date '
    || '     ELSE xmril.warning_date '
    || '   END                          AS  de_prod_date '       -- �w�萻����
    || '  ,NVL(xmril.warning_date, NVL(xmril.designated_production_date, TO_DATE(''19000101'', ''YYYYMMDD''))) '
    || '                                AS  de_prod_date_sort '  -- �w�萻����(�\�[�g�p) 2008/09/26 H.Itou Add T_TE080_BPO_600�w�E38�Ή�
    || '  ,ilm.attribute1               AS  prod_date '          -- ������
    || '  ,ilm.attribute3               AS  best_before_date '   -- �ܖ�����
    || '  ,ilm.attribute2               AS  native_sign '        -- �ŗL�L��
    || '  ,xmld.lot_no                  AS  lot_no '             -- ���b�gNo
    || '  ,xlvv2.meaning                AS  lot_status '         -- �i��
    || '  ,CASE '
    || '     WHEN ximv.conv_unit IS NULL THEN xmld.actual_quantity '
    || '     ELSE (xmld.actual_quantity '
    || '           / TO_NUMBER( '
    || '               CASE '
    || '                 WHEN ximv.num_of_cases > 0 THEN  ximv.num_of_cases '
    || '                 ELSE TO_CHAR(1) '
    || '               END)) '
    || '   END                          AS  req_qty '            -- �˗���
    || '  ,TO_NUMBER(0)                 AS  ins_qty '            -- �s����
    || '  ,NULL                         AS  reserve_order '      -- ������
    || '  ,xmrih.arrival_time_from      AS  time_from '          -- ���Ԏw��From
    || ' FROM '
    || '  ( ' || lv_sql_item_short_stock || ') data ' -- 00:�����ϕ��𒊏o���邽�߂̕s���i�ڂ̃T�u�N�G��
    || '  ,xxinv_mov_req_instr_headers    xmrih '    -- 01:�ړ��˗�/�w���w�b�_�i�A�h�I���j
    || '  ,xxinv_mov_req_instr_lines      xmril '    -- 02:�ړ��˗�/�w�����ׁi�A�h�I���j
    || '  ,xxcmn_item_locations2_v        xilv1 '    -- 03:OPM�ۊǏꏊ���(�o�Ɍ�)
    || '  ,xxcmn_item_locations2_v        xilv2 '    -- 04:OPM�ۊǏꏊ���(���ɐ�)
    || '  ,xxcmn_item_mst2_v              ximv  '    -- 05:OPM�i�ڏ��
    || '  ,xxinv_mov_lot_details          xmld  '    -- 06:�ړ����b�g�ڍ�(�A�h�I��)
    || '  ,ic_lots_mst                    ilm   '    -- 07:OPM���b�g�}�X�^
    || '  ,xxcmn_lookup_values2_v         xlvv1 '    -- 08:�N�C�b�N�R�[�h(�����u���b�N)
    || '  ,xxcmn_lookup_values2_v         xlvv2 '    -- 09:�N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
    || ' WHERE '
         ----------------------------------------------------------------------------------
         -- �s���i�ڏ��i���ݏ���
         ----------------------------------------------------------------------------------
    || '      xmrih.shipped_locat_code   =  data.shipped_cd '
    || ' AND  xmril.item_code            =  data.item_cd '
    || ' AND  xmrih.schedule_ship_date  >=  :shipped_date_from '
    || ' AND  xmrih.schedule_ship_date  <=  data.shipped_date '
-- 2008/10/03 H.Itou Mod Start �����������A�S�����𒊏o�������̂ŁA�s�����ύX
--    || ' AND  (xmril.instruct_qty - xmril.reserved_quantity) <= 0 '
    || ' AND  (xmril.instruct_qty - xmril.reserved_quantity) >= 0 '
-- 2008/10/03 H.Itou Mod End
         ----------------------------------------------------------------------------------
         -- �w�b�_���
         ----------------------------------------------------------------------------------
         -- 01:�ړ��˗�/�w���w�b�_�i�A�h�I���j
    || ' AND  xmrih.status    >=  ''' || gc_move_status_ordered || ''' ' -- �X�e�[�^�X:�˗���
    || ' AND  xmrih.mov_type  <>  ''' || gc_mov_type_not_ship   || ''' ' -- �ړ��^�C�v:�ϑ��Ȃ�
-- 2009/01/07 v1.7 UPDATE START
/*
-- 2008/12/10 H.Itou Add Start
    || ' AND  xmrih.notif_status  <> ''' || gc_notif_status_ktz || ''' '   -- �ʒm�X�e�[�^�X���m��ʒm�ςłȂ�����
-- 2008/12/10 H.Itou Add End
*/
    || ' AND  xmrih.notif_status IN ( ''' || gc_notif_status_mt || ''',''' || gc_notif_status_sty || ''') '   -- �ʒm�X�e�[�^�X���m��ʒm�ςłȂ�����
-- 2009/01/07 v1.7 UPDATE END
         -- 03:OPM�ۊǏꏊ���(�o�Ɍ�)
    || ' AND  xilv1.inventory_location_id = xmrih.shipped_locat_id '
         -- 04:OPM�ۊǏꏊ���(���ɐ�)
    || ' AND  xilv2.inventory_location_id = xmrih.ship_to_locat_id '
         ----------------------------------------------------------------------------------
         -- ���׏��
         ----------------------------------------------------------------------------------
         -- 02:�ړ��˗�/�w�����ׁi�A�h�I���j
    || ' AND  xmrih.mov_hdr_id  =  xmril.mov_hdr_id '
    || ' AND  xmril.delete_flg  <>  ''' || gc_delete_flg || ''' '
         -- 05:OPM�i�ڏ��
    || ' AND  xmril.item_id = ximv.item_id '
         ----------------------------------------------------------------------------------
         -- ���b�g���
         ----------------------------------------------------------------------------------
         -- 06:�ړ����b�g�ڍ�(�A�h�I��)
    || ' AND  xmril.mov_line_id =  xmld.mov_line_id '
    || ' AND  xmril.item_id     =  xmld.item_id '
    || ' AND  xmld.document_type_code = ''' || gc_doc_type_move  || ''' '  -- �����^�C�v:�ړ�
    || ' AND  xmld.record_type_code   = ''' || gc_rec_type_shiji || ''' '  -- ���R�[�h�^�C�v:�w��
         -- 07:OPM���b�g�}�X�^
    || ' AND  xmld.lot_id   =  ilm.lot_id '
    || ' AND  xmld.item_id  =  ilm.item_id '
         ----------------------------------------------------------------------------------
         -- �N�C�b�N�R�[�h
         ----------------------------------------------------------------------------------
         -- 08:�N�C�b�N�R�[�h(�����u���b�N)
    || ' AND  xlvv1.lookup_type = ''' || gc_lookup_cd_block || ''' '
    || ' AND  xilv1.distribution_block = xlvv1.lookup_code '
         -- 09:�N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
    || ' AND  xlvv2.lookup_type = ''' || gc_lookup_cd_lot_status || ''' '
    || ' AND  ilm.attribute23 = xlvv2.lookup_code '
         ----------------------------------------------------------------------------------
         -- �K�p��
         ----------------------------------------------------------------------------------
         -- 03:OPM�ۊǏꏊ(�o�Ɍ�)
    || ' AND  xilv1.date_from <= xmrih.schedule_ship_date '
    || ' AND  ((xilv1.date_to IS NULL) '
    || '   OR  (xilv1.date_to >= xmrih.schedule_ship_date)) '
         -- 04:OPM�ۊǏꏊ(���Ɍ�)
    || ' AND  xilv2.date_from <= xmrih.schedule_ship_date '
    || ' AND  ((xilv2.date_to IS NULL) '
    || '   OR  (xilv2.date_to >= xmrih.schedule_ship_date)) '
         -- 05:OPM�i�ڏ��
    || ' AND  ximv.start_date_active  <= xmrih.schedule_ship_date '
    || ' AND ((ximv.end_date_active IS NULL) '
    || '   OR (ximv.end_date_active  >= xmrih.schedule_ship_date)) '
         -- 08:�N�C�b�N�R�[�h(�����u���b�N)
    || ' AND  xlvv1.start_date_active  <= xmrih.schedule_ship_date '
    || ' AND ((xlvv1.end_date_active IS NULL) '
    || '   OR (xlvv1.end_date_active  >= xmrih.schedule_ship_date)) '
         -- 09:�N�C�b�N�R�[�h(���b�g�X�e�[�^�X)
    || ' AND  xlvv2.start_date_active  <= xmrih.schedule_ship_date '
    || ' AND ((xlvv2.end_date_active IS NULL) '
    || '   OR (xlvv2.end_date_active  >= xmrih.schedule_ship_date)) '
-- 2008/11/13 v1.4 T.Yoshimoto Add Start
    || ' AND ((xmrih.no_instr_actual_class <> ''' || gc_move_instr_actual_class || ''') '
    || '   OR (xmrih.no_instr_actual_class IS NULL)) '
-- 2008/11/13 v1.4 T.Yoshimoto Add End
    ;
--
    -- ======================================
    -- ORDER BY��쐬
    -- ======================================
    lv_order_by :=
       ' ORDER BY '
    || '   block_cd       ASC '     -- 01:�u���b�N
    || '  ,shipped_cd     ASC '     -- 02:�o�Ɍ�
    || '  ,item_cd        ASC '     -- 03:�i��
    || '  ,shipped_date   ASC '     -- 04:�o�ɓ�
    || '  ,arrival_date   ASC '     -- 05:����
    || '  ,de_prod_date_sort  DESC '-- 06:�w�萻���� 2008/09/26 H.Itou Mod T_TE080_BPO_600�w�E38�Ή�
    || '  ,reserve_order  ASC '     -- 07:������
    || '  ,base_cd        ASC '     -- 08:�Ǌ����_
    || '  ,time_from      ASC '     -- 09:���Ԏw��From
    || '  ,req_move_no    ASC '     -- 10:�˗�No/�ړ�No
    || '  ,lot_no         ASC '     -- 11:���b�gNo
    ;
--
    -- ======================================
    -- SQL�쐬
    -- ======================================
    lv_sql := lv_sql_wsh_short_stock -- �s�����擾(�o��)SQL
           || cv_union_all           -- UNION ALL
           || lv_sql_wsh_stock       -- �s��������(�o��)SQL
           || cv_union_all           -- UNION ALL
           || lv_sql_inv_short_stock -- �s�����擾(�ړ�)SQL
           || cv_union_all           -- UNION ALL
           || lv_sql_inv_stock       -- �s��������(�ړ�)SQL
           || lv_order_by            -- ORDER BY��
           ;
--
    -- ======================================
    -- �J�[�\��OPEN
    -- ======================================
    OPEN  cur_data FOR lv_sql
    USING ----------------------------------
          -- �s�����擾(�o��)SQL�p�����[�^
          ----------------------------------
          gt_param.shipped_date_from                      -- WHERE�� �o�ɓ�           >= IN�p�����[�^.�o�ɓ�FROM
         ,gt_param.shipped_date_to                        -- WHERE�� �o�ɓ�           <= IN�p�����[�^.�o�ɓ�TO
         ,NVL(gt_param.tighten_time_from, gc_time_start)  -- WHERE�� ���ߎ��{��(����) >= IN�p�����[�^.���ߎ��{����FROM
         ,NVL(gt_param.tighten_time_to,   gc_time_end)    -- WHERE�� ���ߎ��{��(����) <= IN�p�����[�^.���ߎ��{����TO
         ,gt_param.tighten_date                           -- WHERE�� ���ߎ��{��        = IN�p�����[�^.���ߎ��{��
         ,gt_param.item_cd                                -- WHERE�� �i��              = IN�p�����[�^.�i��
         ,gt_param.shipped_cd                             -- WHERE�� �o�Ɍ�            = IN�p�����[�^.�o�Ɍ�
         ,gt_param.block1                                 -- WHERE�� �����u���b�N      = IN�p�����[�^.�u���b�N1
         ,gt_param.block2                                 -- WHERE�� �����u���b�N      = IN�p�����[�^.�u���b�N2
         ,gt_param.block3                                 -- WHERE�� �����u���b�N      = IN�p�����[�^.�u���b�N3
          ----------------------------------
          -- �s�������擾(�o��)SQL�p�����[�^
          ----------------------------------
          -- ** �T�u�N�G���̃p�����[�^(�����ϕ��𒊏o���邽�߂̕s���i�ڂ̎擾(�o��)) ** --
         ,gt_param.shipped_date_from                      -- WHERE�� �o�ɓ�           >= IN�p�����[�^.�o�ɓ�FROM
         ,gt_param.shipped_date_to                        -- WHERE�� �o�ɓ�           <= IN�p�����[�^.�o�ɓ�TO
         ,NVL(gt_param.tighten_time_from, gc_time_start)  -- WHERE�� ���ߎ��{��(����) >= IN�p�����[�^.���ߎ��{����FROM
         ,NVL(gt_param.tighten_time_to,   gc_time_end)    -- WHERE�� ���ߎ��{��(����) <= IN�p�����[�^.���ߎ��{����TO
         ,gt_param.tighten_date                           -- WHERE�� ���ߎ��{��        = IN�p�����[�^.���ߎ��{��
         ,gt_param.item_cd                                -- WHERE�� �i��              = IN�p�����[�^.�i��
         ,gt_param.shipped_cd                             -- WHERE�� �o�Ɍ�            = IN�p�����[�^.�o�Ɍ�
         ,gt_param.block1                                 -- WHERE�� �����u���b�N      = IN�p�����[�^.�u���b�N1
         ,gt_param.block2                                 -- WHERE�� �����u���b�N      = IN�p�����[�^.�u���b�N2
         ,gt_param.block3                                 -- WHERE�� �����u���b�N      = IN�p�����[�^.�u���b�N3
          -- ** �T�u�N�G���̃p�����[�^(�����ϕ��𒊏o���邽�߂̕s���i�ڂ̎擾(�ړ�)) ** --
         ,gt_param.shipped_date_from                      -- WHERE�� �o�ɓ�           >= IN�p�����[�^.�o�ɓ�FROM
         ,gt_param.shipped_date_to                        -- WHERE�� �o�ɓ�           <= IN�p�����[�^.�o�ɓ�TO
         ,gt_param.item_cd                                -- WHERE�� �i��              = IN�p�����[�^.�i��
         ,gt_param.shipped_cd                             -- WHERE�� �o�Ɍ�            = IN�p�����[�^.�o�Ɍ�
         ,gt_param.block1                                 -- WHERE�� �����u���b�N      = IN�p�����[�^.�u���b�N1
         ,gt_param.block2                                 -- WHERE�� �����u���b�N      = IN�p�����[�^.�u���b�N2
         ,gt_param.block3                                 -- WHERE�� �����u���b�N      = IN�p�����[�^.�u���b�N3
          -- ** ���C���̃p�����[�^ ** --
         ,gt_param.shipped_date_from                      -- WHERE�� �o�ɓ�           >= IN�p�����[�^.�o�ɓ�FROM
         ,NVL(gt_param.tighten_time_from, gc_time_start)  -- WHERE�� ���ߎ��{��(����) >= IN�p�����[�^.���ߎ��{����FROM
         ,NVL(gt_param.tighten_time_to,   gc_time_end)    -- WHERE�� ���ߎ��{��(����) <= IN�p�����[�^.���ߎ��{����TO
         ,gt_param.tighten_date                           -- WHERE�� ���ߎ��{��        = IN�p�����[�^.���ߎ��{��
          ----------------------------------
          -- �s�����擾(�ړ�)SQL�p�����[�^
          ----------------------------------
         ,gt_param.shipped_date_from                      -- WHERE�� �o�ɓ�           >= IN�p�����[�^.�o�ɓ�FROM
         ,gt_param.shipped_date_to                        -- WHERE�� �o�ɓ�           <= IN�p�����[�^.�o�ɓ�TO
         ,gt_param.item_cd                                -- WHERE�� �i��              = IN�p�����[�^.�i��
         ,gt_param.shipped_cd                             -- WHERE�� �o�Ɍ�            = IN�p�����[�^.�o�Ɍ�
         ,gt_param.block1                                 -- WHERE�� �����u���b�N      = IN�p�����[�^.�u���b�N1
         ,gt_param.block2                                 -- WHERE�� �����u���b�N      = IN�p�����[�^.�u���b�N2
         ,gt_param.block3                                 -- WHERE�� �����u���b�N      = IN�p�����[�^.�u���b�N3
          ----------------------------------
          -- �s�������擾(�ړ�)SQL�p�����[�^
          ----------------------------------
          -- ** �T�u�N�G���̃p�����[�^(�����ϕ��𒊏o���邽�߂̕s���i�ڂ̎擾(�o��)) ** --
         ,gt_param.shipped_date_from                      -- WHERE�� �o�ɓ�           >= IN�p�����[�^.�o�ɓ�FROM
         ,gt_param.shipped_date_to                        -- WHERE�� �o�ɓ�           <= IN�p�����[�^.�o�ɓ�TO
         ,NVL(gt_param.tighten_time_from, gc_time_start)  -- WHERE�� ���ߎ��{��(����) >= IN�p�����[�^.���ߎ��{����FROM
         ,NVL(gt_param.tighten_time_to,   gc_time_end)    -- WHERE�� ���ߎ��{��(����) <= IN�p�����[�^.���ߎ��{����TO
         ,gt_param.tighten_date                           -- WHERE�� ���ߎ��{��        = IN�p�����[�^.���ߎ��{��
         ,gt_param.item_cd                                -- WHERE�� �i��              = IN�p�����[�^.�i��
         ,gt_param.shipped_cd                             -- WHERE�� �o�Ɍ�            = IN�p�����[�^.�o�Ɍ�
         ,gt_param.block1                                 -- WHERE�� �����u���b�N      = IN�p�����[�^.�u���b�N1
         ,gt_param.block2                                 -- WHERE�� �����u���b�N      = IN�p�����[�^.�u���b�N2
         ,gt_param.block3                                 -- WHERE�� �����u���b�N      = IN�p�����[�^.�u���b�N3
          -- ** �T�u�N�G���̃p�����[�^(�����ϕ��𒊏o���邽�߂̕s���i�ڂ̎擾(�ړ�)) ** --
         ,gt_param.shipped_date_from                      -- WHERE�� �o�ɓ�           >= IN�p�����[�^.�o�ɓ�FROM
         ,gt_param.shipped_date_to                        -- WHERE�� �o�ɓ�           <= IN�p�����[�^.�o�ɓ�TO
         ,gt_param.item_cd                                -- WHERE�� �i��              = IN�p�����[�^.�i��
         ,gt_param.shipped_cd                             -- WHERE�� �o�Ɍ�            = IN�p�����[�^.�o�Ɍ�
         ,gt_param.block1                                 -- WHERE�� �����u���b�N      = IN�p�����[�^.�u���b�N1
         ,gt_param.block2                                 -- WHERE�� �����u���b�N      = IN�p�����[�^.�u���b�N2
         ,gt_param.block3                                 -- WHERE�� �����u���b�N      = IN�p�����[�^.�u���b�N3
          -- ** ���C���̃p�����[�^ ** --
         ,gt_param.shipped_date_from                      -- WHERE�� �o�ɓ�           >= IN�p�����[�^.�o�ɓ�FROM
    ;
--
    -- ======================================
    -- �J�[�\��FETCH
    -- ======================================
    FETCH cur_data BULK COLLECT INTO gt_report_data ;
--
    -- ======================================
    -- �J�[�\��CLOSE
    -- ======================================
    CLOSE cur_data ;
-- 2008/09/26 H.Itou Add End T_S_533(PT�Ή�)
--
-- 2009/01/14 v1.8 ADD START
--
    -- ====================================================
    -- ���[�f�[�^�쐬
    -- ====================================================
--
    <<select_data_loop>>
    FOR i IN 1..gt_report_data.COUNT LOOP
--
      -- �����l�ݒ�
      IF (i = 1) THEN
        lv_block_cd       := gt_report_data(i).block_cd ;    -- �O�񃌃R�[�h�i�[�p�i�u���b�N�R�[�h�j
        lv_tmp_shipped_cd := gt_report_data(i).shipped_cd;   -- �O�񃌃R�[�h�i�[�p�i�o�Ɍ��R�[�h�j
        lv_tmp_item_cd    := gt_report_data(i).item_cd;      -- �O�񃌃R�[�h�i�[�p�i�i�ڃR�[�h�j
        ln_report_data_fr := i;                              -- �����[�f�[�^�̊i�[�p�ԍ��i���j
      END IF;
--      
      -- �u���b�N�R�[�h�A�o�Ɍ��R�[�h�A�i�ڃR�[�h�̑g��������v����ꍇ
      IF   (lv_block_cd       = gt_report_data(i).block_cd)
      AND  (lv_tmp_shipped_cd = gt_report_data(i).shipped_cd)
      AND  (lv_tmp_item_cd    = gt_report_data(i).item_cd)    THEN
        -- �s�����̏W�v
        ln_ins_qty         := ln_ins_qty + NVL(gt_report_data(i).ins_qty,0);
        -- �����[�f�[�^�̊i�[�p�ԍ��i���j�̐ݒ�
        ln_report_data_to  := i;
      -- �u���b�N�R�[�h�A�o�Ɍ��R�[�h�A�i�ڃR�[�h�̑g��������v���Ȃ��ꍇ
      ELSE
        -- �u���b�N�R�[�h�A�o�Ɍ��R�[�h�A�i�ڃR�[�h�P�ʂ̕s�����̏W�v��0�ȊO
        IF (ln_ins_qty <> 0) THEN
          -- �o�̓f�[�^�i���[�N�j�ɒl��ݒ肷��i���[�v���j
          <<report_data_in_loop>>
          FOR ln_line_loop_cnt IN ln_report_data_fr..ln_report_data_to LOOP
            ln_report_data_cnt := ln_report_data_cnt + 1;
-- 2009/01/20 v1.9 ADD START
            -- �˗�No/�ړ�No���O�̃��R�[�h�Ɠ����ꍇ
            IF  (lv_req_move_no = gt_report_data(ln_line_loop_cnt).req_move_no) THEN
              gt_report_data(ln_line_loop_cnt).req_move_no     :=  NULL;      -- �˗�No/�ړ�No
              gt_report_data(ln_line_loop_cnt).base_cd         :=  NULL;      -- �Ǌ����_
              gt_report_data(ln_line_loop_cnt).base_nm         :=  NULL;      -- �Ǌ����_����
              gt_report_data(ln_line_loop_cnt).delivery_to_cd  :=  NULL;      -- �z����/���ɐ�
              gt_report_data(ln_line_loop_cnt).delivery_to_nm  :=  NULL;      -- �z���於��
              gt_report_data(ln_line_loop_cnt).description     :=  NULL;      -- �E�v
              gt_report_data(ln_line_loop_cnt).conf_req        :=  NULL;      -- �m�F�˗�
            -- �˗�No/�ړ�No���O�̃��R�[�h�ƈقȂ�ꍇ
            ELSE
              lv_req_move_no := gt_report_data(ln_line_loop_cnt).req_move_no;
            END IF;
-- 2009/01/20 v1.9 ADD END
            lt_report_data(ln_report_data_cnt) := gt_report_data(ln_line_loop_cnt);
          END LOOP report_data_in_loop;
        END IF;
        -- �l�ݒ�
        lv_block_cd       := gt_report_data(i).block_cd ;      -- �O�񃌃R�[�h�i�[�p�i�u���b�N�R�[�h�j
        lv_tmp_shipped_cd := gt_report_data(i).shipped_cd;     -- �O�񃌃R�[�h�i�[�p�i�o�Ɍ��R�[�h�j
        lv_tmp_item_cd    := gt_report_data(i).item_cd;        -- �O�񃌃R�[�h�i�[�p�i�i�ڃR�[�h�j
        ln_ins_qty        := NVL(gt_report_data(i).ins_qty,0); 
        ln_report_data_fr := i;                                -- �����[�f�[�^�̊i�[�p�ԍ��i���j
        ln_report_data_to := i;                                -- �����[�f�[�^�̊i�[�p�ԍ��i���j
      END IF;
    END LOOP select_data_loop;
--
    -- �o�Ɍ��R�[�h�ƕi�ڃR�[�h�̒P�ʂ̕s�����̏W�v��0�ȊO
    IF (ln_ins_qty <> 0) THEN
      -- �o�̓f�[�^�i���[�N�j�ɒl��ݒ肷��i���[�v�O�j
      <<report_data_out_loop>>
      FOR ln_line_loop_cnt IN ln_report_data_fr..ln_report_data_to LOOP
          ln_report_data_cnt := ln_report_data_cnt + 1;
-- 2009/01/20 v1.9 ADD START
          -- �˗�No/�ړ�No���O�̃��R�[�h�Ɠ����ꍇ
          IF  (lv_req_move_no = gt_report_data(ln_line_loop_cnt).req_move_no) THEN
            gt_report_data(ln_line_loop_cnt).req_move_no     :=  NULL;      -- �˗�No/�ړ�No
            gt_report_data(ln_line_loop_cnt).base_cd         :=  NULL;      -- �Ǌ����_
            gt_report_data(ln_line_loop_cnt).base_nm         :=  NULL;      -- �Ǌ����_����
            gt_report_data(ln_line_loop_cnt).delivery_to_cd  :=  NULL;      -- �z����/���ɐ�
            gt_report_data(ln_line_loop_cnt).delivery_to_nm  :=  NULL;      -- �z���於��
            gt_report_data(ln_line_loop_cnt).description     :=  NULL;      -- �E�v
            gt_report_data(ln_line_loop_cnt).conf_req        :=  NULL;      -- �m�F�˗�
          -- �˗�No/�ړ�No���O�̃��R�[�h�ƈقȂ�ꍇ
          ELSE
            lv_req_move_no := gt_report_data(ln_line_loop_cnt).req_move_no;
          END IF;
-- 2009/01/20 v1.9 ADD END
          lt_report_data(ln_report_data_cnt) := gt_report_data(ln_line_loop_cnt);
      END LOOP report_data_out_loop;
    END IF;
--
    gt_report_data.DELETE;
    gt_report_data := lt_report_data;
-- 2009/01/14 v1.8 ADD END
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( cur_data%ISOPEN ) THEN
        CLOSE cur_data ;
      END IF ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( cur_data%ISOPEN ) THEN
        CLOSE cur_data ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( cur_data%ISOPEN ) THEN
        CLOSE cur_data ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_report_data;
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : XML��������
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
    ov_errbuf     OUT  VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT  VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT  VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ;   -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���ϐ� ***
    -- �O�񃌃R�[�h�i�[�p
    lv_tmp_shipped_cd    type_report_data.shipped_cd%TYPE DEFAULT NULL ;    -- �o�Ɍ��R�[�h
    lv_tmp_item_cd       type_report_data.item_cd%TYPE DEFAULT NULL ;       -- �i�ڃR�[�h
    lv_tmp_shipped_date  type_report_data.shipped_date%TYPE DEFAULT NULL ;  -- �o�ɓ�
    lv_tmp_arrival_date  type_report_data.arrival_date%TYPE DEFAULT NULL ;  -- ����
    lv_tmp_biz_type      type_report_data.biz_type%TYPE DEFAULT NULL ;      -- �Ɩ����
--
    -- �^�O�o�͔���t���O
    lb_dispflg_shipped_cd   BOOLEAN DEFAULT TRUE ;       -- �o�Ɍ��R�[�h
    lb_dispflg_item_cd      BOOLEAN DEFAULT TRUE ;       -- �i�ڃR�[�h
    lb_dispflg_shipped_date BOOLEAN DEFAULT TRUE ;       -- �o�ɓ�
    lb_dispflg_arrival_date BOOLEAN DEFAULT TRUE ;       -- ����
    lb_dispflg_biz_type     BOOLEAN DEFAULT TRUE ;       -- �Ɩ����
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- -----------------------------------------------------
    -- �w�b�_���ݒ�
    -- -----------------------------------------------------
    prc_set_tag_data('root') ;
    prc_set_tag_data('data_info') ;
    prc_set_tag_data('report_id', gc_report_id);
    prc_set_tag_data('exec_time', TO_CHAR(SYSDATE, gc_date_fmt_all));
    prc_set_tag_data('dep_cd', gv_dept_cd);
    prc_set_tag_data('dep_nm', gv_dept_nm);
    prc_set_tag_data('shipped_date_from', TO_CHAR(gt_param.shipped_date_from ,gc_date_fmt_ymd_ja));
    prc_set_tag_data('shipped_date_to', TO_CHAR(gt_param.shipped_date_to ,gc_date_fmt_ymd_ja));
    prc_set_tag_data('lg_shipped_info') ;
--
    -- -----------------------------------------------------
    -- ���[0���pXML�f�[�^�쐬
    -- -----------------------------------------------------
    IF (gt_report_data.COUNT = 0) THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg(gc_application_cmn, gc_msg_id_no_data) ;
--
      prc_set_tag_data('g_shipped_info') ;
      prc_set_tag_data('msg', ov_errmsg) ;
      prc_set_tag_data('/g_shipped_info') ;
    END IF ;
--
    -- -----------------------------------------------------
    -- XML�f�[�^�쐬
    -- -----------------------------------------------------
    <<set_data_loop>>
    FOR i IN 1..gt_report_data.COUNT LOOP
--
      -- ====================================================
      -- XML�f�[�^�ݒ�
      -- ====================================================
      -- �w�b�_��(�o�Ɍ��O���[�v)
      IF (lb_dispflg_shipped_cd) THEN
        prc_set_tag_data('g_shipped_info') ;
        prc_set_tag_data('block_cd', gt_report_data(i).block_cd) ;
        prc_set_tag_data('block_nm', gt_report_data(i).block_nm) ;
        prc_set_tag_data('shipped_cd', gt_report_data(i).shipped_cd) ;
        prc_set_tag_data('shipped_nm', gt_report_data(i).shipped_nm) ;
        prc_set_tag_data('lg_item_info') ;
      END IF ;
--
      -- �w�b�_��(�i�ڃO���[�v)
      IF (lb_dispflg_item_cd) THEN
        prc_set_tag_data('g_item_info') ;
        prc_set_tag_data('item_cd', gt_report_data(i).item_cd) ;
        prc_set_tag_data('item_nm', gt_report_data(i).item_nm) ;
        prc_set_tag_data('lg_shipped_date_info') ;
      END IF ;
--
      -- �w�b�_��(�o�ɓ��O���[�v)
      IF (lb_dispflg_shipped_date) THEN
        prc_set_tag_data('g_shipped_date_info') ;
        prc_set_tag_data('shipped_date', fnc_chgdt_c(gt_report_data(i).shipped_date)) ;
        prc_set_tag_data('lg_req_move_info') ;
      END IF ;
--
      -- �Ɩ���� �\������
      IF ((lv_tmp_biz_type != gt_report_data(i).biz_type) OR lb_dispflg_shipped_date) THEN
        lb_dispflg_biz_type := TRUE ;
      ELSE
        lb_dispflg_biz_type := FALSE ;
      END IF ;
--
      -- ���� �\������
      IF ((lv_tmp_arrival_date != gt_report_data(i).arrival_date) OR lb_dispflg_shipped_date) THEN
        lb_dispflg_arrival_date := TRUE ;
        lb_dispflg_biz_type := TRUE ;
      ELSE
        lb_dispflg_arrival_date := FALSE ;
      END IF ;
--
      -- ���ו�(�˗�No/�ړ�No�O���[�v)
      prc_set_tag_data('g_req_move_info') ;
--
      IF (lb_dispflg_arrival_date) THEN
        -- ���� 1�s�O�ƒl���قȂ�ꍇ�̂ݕ\��
        prc_set_tag_data('arrive_date', fnc_chgdt_c(gt_report_data(i).arrival_date));
      END IF ;
--
      IF (lb_dispflg_biz_type) THEN
        -- �Ɩ���� 1�s�O�ƒl���قȂ�ꍇ�̂ݕ\��
        prc_set_tag_data('biz_type', gt_report_data(i).biz_type);
      END IF ;
--
      prc_set_tag_data('req_move_no'     , gt_report_data(i).req_move_no);
      prc_set_tag_data('base_cd'         , gt_report_data(i).base_cd);
      prc_set_tag_data('base_nm'         , gt_report_data(i).base_nm);
      prc_set_tag_data('deli_to_cd'      , gt_report_data(i).delivery_to_cd);
      prc_set_tag_data('deli_to_nm'      , gt_report_data(i).delivery_to_nm);
      prc_set_tag_data('description'     , gt_report_data(i).description);
      prc_set_tag_data('confirm_req'     , gt_report_data(i).conf_req);
      prc_set_tag_data('de_prod_date'    , fnc_chgdt_c(gt_report_data(i).de_prod_date)) ;
      prc_set_tag_data('prod_date'       , gt_report_data(i).prod_date) ;
      prc_set_tag_data('best_before_date', gt_report_data(i).best_before_date) ;
      prc_set_tag_data('native_sign'     , gt_report_data(i).native_sign) ;
      prc_set_tag_data('lot_no'          , gt_report_data(i).lot_no) ;
      prc_set_tag_data('lot_status'      , gt_report_data(i).lot_status) ;
      prc_set_tag_data('req_qty'         , gt_report_data(i).req_qty) ;
      prc_set_tag_data('ins_qty'         , gt_report_data(i).ins_qty) ;
      prc_set_tag_data('/g_req_move_info') ;
--
      -- ====================================================
      -- ���ݏ������̃f�[�^��ێ�
      -- ====================================================
      lv_tmp_shipped_cd   := gt_report_data(i).shipped_cd ;    -- �o�Ɍ��R�[�h
      lv_tmp_item_cd      := gt_report_data(i).item_cd ;       -- �i�ڃR�[�h
      lv_tmp_shipped_date := gt_report_data(i).shipped_date ;  -- �o�ɓ�
      lv_tmp_arrival_date := gt_report_data(i).arrival_date ;  -- ����
      lv_tmp_biz_type     := gt_report_data(i).biz_type ;      -- �Ɩ����
--
      -- ====================================================
      -- �o�͔���
      -- ====================================================
      IF (i < gt_report_data.COUNT) THEN
        -- �o�ɓ�
        IF (lv_tmp_shipped_date = gt_report_data(i + 1).shipped_date) THEN
          lb_dispflg_shipped_date := FALSE ;
        ELSE
          lb_dispflg_shipped_date := TRUE ;
        END IF ;
--
        -- �i�ڃR�[�h
        IF (lv_tmp_item_cd = gt_report_data(i + 1).item_cd) THEN
          lb_dispflg_item_cd      := FALSE ;
        ELSE
          lb_dispflg_shipped_date := TRUE ;
          lb_dispflg_item_cd      := TRUE ;
        END IF ;
--
        -- �o�Ɍ��R�[�h
        IF (lv_tmp_shipped_cd = gt_report_data(i + 1).shipped_cd) THEN
          lb_dispflg_shipped_cd   := FALSE ;
        ELSE
          lb_dispflg_shipped_date := TRUE ;
          lb_dispflg_item_cd      := TRUE ;
          lb_dispflg_shipped_cd   := TRUE ;
        END IF ;
      ELSE
          lb_dispflg_shipped_date := TRUE ; 
          lb_dispflg_item_cd      := TRUE ; 
          lb_dispflg_shipped_cd   := TRUE ; 
      END IF;
--
      -- ====================================================
      -- �I���^�O�ݒ�
      -- ====================================================
      IF (lb_dispflg_shipped_date) THEN
        prc_set_tag_data('/lg_req_move_info') ;
        prc_set_tag_data('/g_shipped_date_info') ;
      END IF;
--
      IF (lb_dispflg_item_cd) THEN
        prc_set_tag_data('/lg_shipped_date_info') ;
        prc_set_tag_data('/g_item_info') ;
      END IF;
--
      IF (lb_dispflg_shipped_cd) THEN
        prc_set_tag_data('/lg_item_info') ;
        prc_set_tag_data('/g_shipped_info') ;
      END IF;
--
    END LOOP set_data_loop;
--
    -- ====================================================
    -- �I���^�O�ݒ�
    -- ====================================================
    prc_set_tag_data('/lg_shipped_info') ;
    prc_set_tag_data('/data_info') ;
    prc_set_tag_data('/root') ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_create_xml_data;
--
  /**********************************************************************************
   * Function Name    : fnc_convert_into_xml
   * Description      : XML�f�[�^�ϊ�
   ***********************************************************************************/
  FUNCTION fnc_convert_into_xml(
    ir_xml  IN  xml_rec
  ) RETURN VARCHAR2
  IS
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_data VARCHAR2(2000);
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF (ir_xml.tag_type = 'D') THEN
      lv_data :=
    '<'|| ir_xml.tag_name || '><![CDATA[' || ir_xml.tag_value || ']]></' || ir_xml.tag_name || '>';
    ELSE
      lv_data := '<' || ir_xml.tag_name || '>';
    END IF ;
--
    RETURN(lv_data);
--
  END fnc_convert_into_xml;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT   VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT   VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT   VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain' ;  -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    ln_retcode       NUMBER ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================================
    -- ��������
    -- ===============================================
    prc_initialize(
      ov_errbuf     => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ===============================================
    -- ���[�f�[�^�擾����
    -- ===============================================
    prc_get_report_data(
      ov_errbuf        => lv_errbuf       --�G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode       => lv_retcode      --���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg        => lv_errmsg       --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- XML��������
    -- ==================================================
    prc_create_xml_data(
      ov_errbuf        => lv_errbuf       --�G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode       => lv_retcode      --���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg        => lv_errmsg       --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- XML�o�͏���
    -- ==================================================
    -- XML�w�b�_���o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>') ;
--
    -- XML�f�[�^���o��
    <<xml_loop>>
    FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
      -- XML�f�[�^�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, fnc_convert_into_xml(gt_xml_data_table(i))) ;
    END LOOP xml_loop ;
--
    --XML�f�[�^�폜
    gt_xml_data_table.DELETE ;
--
    IF ((lv_retcode = gv_status_warn) AND (gt_report_data.COUNT = 0)) THEN
      RAISE no_data_expt ;
    END IF ;
--
  EXCEPTION
    -- *** ���[0����O�n���h�� ***
    WHEN no_data_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_warn;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
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
     errbuf                 OUT    VARCHAR2      -- �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode                OUT    VARCHAR2      -- ���^�[���E�R�[�h    --# �Œ� #
    ,iv_block1              IN     VARCHAR2      -- 01:�u���b�N1
    ,iv_block2              IN     VARCHAR2      -- 02:�u���b�N2
    ,iv_block3              IN     VARCHAR2      -- 03:�u���b�N3
    ,iv_tighten_date        IN     VARCHAR2      -- 04:���ߎ��{��
    ,iv_tighten_time_from   IN     VARCHAR2      -- 05:���ߎ��{����From
    ,iv_tighten_time_to     IN     VARCHAR2      -- 06:���ߎ��{����To
    ,iv_shipped_cd          IN     VARCHAR2      -- 07:�o�Ɍ�
    ,iv_item_cd             IN     VARCHAR2      -- 08:�i��
    ,iv_shipped_date_from   IN     VARCHAR2      -- 09:�o�ɓ�From
    ,iv_shipped_date_to     IN     VARCHAR2      -- 10:�o�ɓ�To
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main' ; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- �ϐ������ݒ�
    -- ===============================================
    -- ���̓p�����[�^���O���[�o���ϐ��ɕێ�
    gt_param.block1            := iv_block1 ;                           -- 01:�u���b�N1
    gt_param.block2            := iv_block2 ;                           -- 02:�u���b�N2
    gt_param.block3            := iv_block3 ;                           -- 03:�u���b�N3
    gt_param.tighten_date      := fnc_chgdt_d(iv_tighten_date) ;        -- 04:���ߎ��{��
    gt_param.tighten_time_from := iv_tighten_time_from ;                -- 05:���ߎ��{����From
    gt_param.tighten_time_to   := iv_tighten_time_to ;                  -- 06:���ߎ��{����To
    gt_param.shipped_cd        := iv_shipped_cd ;                       -- 07:�o�Ɍ�
    gt_param.item_cd           := iv_item_cd ;                          -- 08:�i��
    gt_param.shipped_date_from := fnc_chgdt_d(iv_shipped_date_from) ;   -- 09:�o�ɓ�From
    gt_param.shipped_date_to   := fnc_chgdt_d(iv_shipped_date_to) ;     -- 10:�o�ɓ�To
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      ov_errbuf    => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errbuf) ;
--
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errbuf) ;
--
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gc_pkg_name || gv_msg_cont || cv_prg_name || gv_msg_part|| SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gc_pkg_name || gv_msg_cont || cv_prg_name || gv_msg_part || SQLERRM ;
      retcode := gv_status_error ;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxwsh620001c;
/
