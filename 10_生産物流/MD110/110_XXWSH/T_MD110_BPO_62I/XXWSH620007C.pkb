CREATE OR REPLACE PACKAGE BODY xxwsh620007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620007c(body)
 * Description      : �q�ɕ��o�w�����i�z���斾�ׁj
 * MD.050           : ����/�z��(���[) T_MD050_BPO_621
 * MD.070           : �q�ɕ��o�w�����i�z���斾�ׁj T_MD070_BPO_62I
 * Version          : 1.4
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
 *  2008/05/14    1.0   Nozomi Kashiwagi   �V�K�쐬
 *  2008/06/24    1.1   Masayoshi Uehara   �x���̏ꍇ�A�p�����[�^�z����/���ɐ�̃����[�V������
 *                                         vendor_site_code�ɕύX�B
 *  2008/07/04    1.2   Satoshi Yunba      �֑������Ή�
 *  2008/07/10    1.3   Naoki Fukuda       ���b�gNo.��NULL���ƕi�ڂ�����Ă��ꊇ��ŏo�͂����
 *  2008/08/05    1.4   Akiyoshi Shiina    ST�s�#519�Ή�
 *
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
  no_data_expt       EXCEPTION;  -- ���[0����O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- ���[���
  gc_pkg_name                CONSTANT  VARCHAR2(12) := 'xxwsh620007c' ;  -- �p�b�P�[�W��
  gc_report_id               CONSTANT  VARCHAR2(12) := 'XXWSH620007T' ;  -- ���[ID
  -- ���t�t�H�[�}�b�g
  gc_date_fmt_all            CONSTANT  VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS' ; -- �N���������b
  gc_date_fmt_ymd            CONSTANT  VARCHAR2(10) := 'YYYY/MM/DD' ;            -- �N����
  -- �o�̓^�O
  gc_tag_type_tag            CONSTANT  VARCHAR2(1)  := 'T' ;                 -- �O���[�v�^�O
  gc_tag_type_data           CONSTANT  VARCHAR2(1)  := 'D' ;                 -- �f�[�^�^�O
  ------------------------------
  -- �o�ׁE�x���E�ړ�����
  ------------------------------
  -- �Ɩ����
  gc_biz_type_cd_ship        CONSTANT  VARCHAR2(1)  := '1' ;
  gc_biz_type_cd_supply      CONSTANT  VARCHAR2(1)  := '2' ;
  gc_biz_type_cd_move        CONSTANT  VARCHAR2(1)  := '3' ;
  gc_biz_type_nm_ship        CONSTANT  VARCHAR2(4)  := '�o��' ;
  gc_biz_type_nm_supply      CONSTANT  VARCHAR2(4)  := '�x��' ;
  gc_biz_type_nm_move        CONSTANT  VARCHAR2(4)  := '�ړ�' ;
  -- �폜�E����t���O
  gc_delete_flg              CONSTANT  VARCHAR2(1)  := 'Y' ;
  -- �����^�C�v
  gc_doc_type_ship           CONSTANT  VARCHAR2(2)  := '10' ;       -- �o�׈˗�
  gc_doc_type_supply         CONSTANT  VARCHAR2(2)  := '30' ;       -- �x���w��
  gc_doc_type_move           CONSTANT  VARCHAR2(2)  := '20' ;       -- �ړ�
  -- ���R�[�h�^�C�v
  gc_rec_type_shiji          CONSTANT  VARCHAR2(2)  := '10' ;       -- �w��
  -- �i�ڋ敪
  gc_item_cd_prod            CONSTANT  VARCHAR2(1)  := '5' ;        -- ���i
  -- ���i�敪
  gc_prod_cd_drink           CONSTANT  VARCHAR2(1)  := '2' ;        -- �h�����N
  ------------------------------
  -- �o�ׁE �x���֘A
  ------------------------------
  -- �o�׎x���敪
  gc_req_kbn_ship            CONSTANT  VARCHAR2(1)  := '1' ;        -- �o�׈˗�
  gc_req_kbn_supply          CONSTANT  VARCHAR2(1)  := '2' ;        -- �x���˗�
  -- �󒍃J�e�S��
  gc_order_cate_ret          CONSTANT  VARCHAR2(10) := 'RETURN' ;   -- �ԕi(�󒍂̂�)
  -- �ŐV�t���O
  gc_new_flg                 CONSTANT  VARCHAR2(1)  := 'Y' ;        -- �ŐV�t���O
  -- �o�׈˗��X�e�[�^�X
  gc_ship_status_close       CONSTANT  VARCHAR2(2)  := '03' ;       -- ���ߍς�
  gc_ship_status_delete      CONSTANT  VARCHAR2(2)  := '99' ;       -- ���
  gc_ship_status_receipt     CONSTANT  VARCHAR2(2)  := '07' ;       -- ��̍�
  ------------------------------
  -- �ړ��֘A
  ------------------------------
  -- �ړ��^�C�v
  gc_mov_type_not_ship       CONSTANT  VARCHAR2(5)  := '2' ;        -- �ϑ��Ȃ�
  -- �ړ��X�e�[�^�X
  gc_move_status_ordered     CONSTANT  VARCHAR2(2)  := '02' ;       -- �˗���
  gc_move_status_delete      CONSTANT  VARCHAR2(2)  := '99' ;       -- ���
  ------------------------------
  -- �N�C�b�N�R�[�h�֘A
  ------------------------------
  -- ���Б��Ћ敪
  gc_lookup_cd_int_ext       CONSTANT  VARCHAR2(30)  := 'XXWSH_621B_INT_EXT_CLASS' ;
  ------------------------------
  -- ���b�Z�[�W�֘A
  ------------------------------
  --�A�v���P�[�V������
  gc_application_wsh         CONSTANT VARCHAR2(5)   := 'XXWSH' ;            -- ��޵�:�o�ץ������z��
  gc_application_cmn         CONSTANT VARCHAR2(5)   := 'XXCMN' ;            -- ��޵�:Ͻ���o�������
  --���b�Z�[�WID
  gc_msg_id_prm_chk          CONSTANT  VARCHAR2(15) := 'APP-XXWSH-12452' ;  -- ���Ұ������װ
  gc_msg_id_no_data          CONSTANT  VARCHAR2(15) := 'APP-XXCMN-10122' ;  -- ���[0���G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���R�[�h�^�錾�p�e�[�u���ʖ��錾
  xoha    xxwsh_order_headers_all%ROWTYPE ;        -- �󒍃w�b�_�A�h�I��
  xola    xxwsh_order_lines_all%ROWTYPE ;          -- �󒍖��׃A�h�I��
  xott2v  xxwsh_oe_transaction_types2_v%ROWTYPE ;  -- �󒍃^�C�v���VIEW2
  xim2v   xxcmn_item_mst2_v%ROWTYPE ;              -- OPM�i�ڏ��VIEW2
  xic3v   xxcmn_item_categories3_v%ROWTYPE ;       -- OPM�i�ڃJ�e�S���������VIEW3
  xmld    xxinv_mov_lot_details%ROWTYPE ;          -- �ړ����b�g�ڍ�(�A�h�I��)
  ilm     ic_lots_mst%ROWTYPE ;                    -- OPM���b�g�}�X�^
  xil2v   xxcmn_item_locations2_v%ROWTYPE ;        -- OPM�ۊǏꏊ���VIEW2
  xcas2v  xxcmn_cust_acct_sites2_v%ROWTYPE ;       -- �ڋq�T�C�g���VIEW2
  xca2v   xxcmn_cust_accounts2_v%ROWTYPE ;         -- �ڋq���VIEW2
  xlv2v   xxcmn_lookup_values2_v%ROWTYPE ;         -- �N�C�b�N�R�[�h���VIEW2
--
  ------------------------------
  -- ���̓p�����[�^�֘A
  ------------------------------
  -- ���̓p�����[�^�i�[�p���R�[�h
  TYPE rec_param_data IS RECORD(
     biz_type      xlv2v.lookup_code%TYPE            -- 01:�Ɩ����  ���K�{
    ,ship_type     xott2v.transaction_type_id%TYPE   -- 02:�o�Ɍ`��
    ,block         xil2v.distribution_block%TYPE     -- 03:�u���b�N
    ,shipped_cd    xil2v.segment1%TYPE               -- 04:�o�Ɍ�
    ,delivery_to   xil2v.segment1%TYPE               -- 05:�z����^���ɐ�
    ,prod_class    xic3v.prod_class_code%TYPE        -- 06:���i�敪  ���K�{
    ,item_class    xic3v.item_class_code%TYPE        -- 07:�i�ڋ敪
    ,shipped_date  DATE                              -- 08:�o�ɓ�    ���K�{
  );
--
  ------------------------------
  -- �o�̓f�[�^�֘A
  ------------------------------
  -- �o�̓f�[�^�i�[�p���R�[�h
  TYPE rec_report_data IS RECORD(
     biz_kind            VARCHAR2(4)                          -- �Ɩ����
    ,trans_type_id       xoha.order_type_id%TYPE              -- �o�Ɍ`��
    ,trans_type_name     xott2v.transaction_type_name%TYPE    -- �o�Ɍ`�Ԗ�
    ,shipped_code        xoha.deliver_from%TYPE               -- �o�Ɍ��R�[�h
    ,shipped_name        xil2v.description%TYPE               -- �o�Ɍ�����
    ,item_class_code     xic3v.item_class_code%TYPE           -- �i�ڋ敪�R�[�h
    ,item_class_name     xic3v.item_class_name%TYPE           -- �i�ڋ敪����
    ,shipped_date        xoha.schedule_ship_date%TYPE         -- �o�ɓ�
    ,int_ext_class_code  xic3v.int_ext_class%TYPE             -- ���O�敪�R�[�h
    ,int_ext_class_name  xlv2v.meaning%TYPE                   -- ���O�敪��
    ,item_code           xola.shipping_item_code%TYPE         -- �i�ڃR�[�h
    ,item_name           xim2v.item_short_name%TYPE           -- �i�ږ���
    ,lot_no              xmld.lot_no%TYPE                     -- ���b�gNo
    ,prod_date           ilm.attribute1%TYPE                  -- ������
    ,best_before_date    ilm.attribute3%TYPE                  -- �ܖ�����
    ,native_sign         ilm.attribute2%TYPE                  -- �ŗL�L��
    ,base_cd             xoha.head_sales_branch%TYPE          -- �Ǌ����_�R�[�h
    ,base_nm             xca2v.party_short_name%TYPE          -- �Ǌ����_����
    ,delivery_to_code    xoha.deliver_to%TYPE                 -- �z����/���ɐ�R�[�h
    ,delivery_to_name    VARCHAR2(60)                         -- �z����/���ɐ於��
    ,req_move_no         xoha.request_no%TYPE                 -- �˗�No
    ,arrive_date         xoha.schedule_arrival_date%TYPE      -- ����
    ,description         VARCHAR2(30)                         -- �E�v
    ,qty                 NUMBER                               -- ����
    ,qty_tani            VARCHAR2(3)                          -- �P��
  );
  type_report_data       rec_report_data;
  TYPE list_report_data  IS TABLE OF rec_report_data INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_param               rec_param_data ;         -- ���̓p�����[�^���
  gt_report_data         list_report_data ;       -- �o�̓f�[�^
  gt_xml_data_table      xml_data ;               -- XML�f�[�^
  gv_dept_cd             VARCHAR2(10) ;           -- �S������
  gv_dept_nm             VARCHAR2(14) ;           -- �S����
  gv_biz_type_nm         VARCHAR2(4) ;            -- �Ɩ���ʖ�
  gv_user_id             fnd_user.user_id%TYPE ;  -- ���[�UID
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
    prm_chk_expt       EXCEPTION;  -- �p�����[�^�`�F�b�N��O
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
    IF ((gt_param.shipped_cd IS NULL) AND (gt_param.block IS NULL)) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_prm_chk
                                           ) ;
      RAISE prm_chk_expt ;
    END IF;
--
  EXCEPTION
    --*** �p�����[�^�`�F�b�N��O�n���h�� ***
    WHEN prm_chk_expt THEN
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
    ----------------------------------------------------------------------------------
    -- �o�׏��
    ----------------------------------------------------------------------------------
    CURSOR cur_data_ship
    IS
      SELECT
         TO_CHAR(gc_biz_type_nm_ship)      AS  biz_kind               -- �Ɩ����
        ,xoha.order_type_id                AS  trans_type_id          -- �o�Ɍ`��
        ,xott2v.transaction_type_name      AS  trans_type_name        -- �o�Ɍ`�Ԗ�
        ,xoha.deliver_from                 AS  shipped_code           -- �o�Ɍ��R�[�h
        ,xil2v.description                 AS  shipped_name           -- �o�Ɍ�����
        ,xic3v.item_class_code             AS  item_class_code        -- �i�ڋ敪�R�[�h
        ,xic3v.item_class_name             AS  item_class_name        -- �i�ڋ敪����
        ,xoha.schedule_ship_date           AS  shipped_date           -- �o�ɓ�
        ,xic3v.int_ext_class               AS  int_ext_class_code     -- ���O�敪�R�[�h
        ,xlv2v.meaning                     AS  int_ext_class_name     -- ���O�敪��
        ,xola.shipping_item_code           AS  item_code              -- �i�ڃR�[�h
        ,xim2v.item_short_name             AS  item_name              -- �i�ږ���
        ,xmld.lot_no                       AS  lot_no                 -- ���b�gNo
        ,ilm.attribute1                    AS  prod_date              -- ������
        ,ilm.attribute3                    AS  best_before_date       -- �ܖ�����
        ,ilm.attribute2                    AS  native_sign            -- �ŗL�L��
        ,xoha.head_sales_branch            AS  base_cd                -- �Ǌ����_�R�[�h
        ,xca2v.party_short_name            AS  base_nm                -- �Ǌ����_����
        ,xoha.deliver_to                   AS  delivery_to_code       -- �z����/���ɐ�R�[�h
        ,xcas2v.party_site_full_name       AS  delivery_to_name       -- �z����/���ɐ於��
        ,xoha.request_no                   AS  req_move_no            -- �˗�No
        ,xoha.schedule_arrival_date        AS  arrive_date            -- ����
        ,SUBSTRB(xoha.shipping_instructions, 1, 30) AS  description   -- �E�v
        ,CASE
         -- ��������Ă���ꍇ
         WHEN ( xola.reserved_quantity > 0 ) THEN
           CASE 
             WHEN  ((xic3v.item_class_code = gc_item_cd_prod)
               AND  (xim2v.conv_unit IS NOT NULL)) THEN
               xmld.actual_quantity / TO_NUMBER(
                                        CASE
                                          WHEN ( xim2v.num_of_cases > 0 ) THEN
                                            xim2v.num_of_cases
                                          ELSE
                                            TO_CHAR(1)
                                        END
                                      )
             ELSE
               xmld.actual_quantity
             END
         -- ��������Ă��Ȃ��ꍇ
         WHEN  ( (xola.reserved_quantity IS NULL) OR (xola.reserved_quantity = 0) ) THEN
           CASE 
             WHEN  ((xic3v.item_class_code = gc_item_cd_prod)
               AND  (xim2v.conv_unit IS NOT NULL) ) THEN
               xola.quantity / TO_NUMBER(
                                 CASE
                                   WHEN ( xim2v.num_of_cases > 0 ) THEN xim2v.num_of_cases
                                   ELSE TO_CHAR(1)
                                 END
                                )
             ELSE
               xola.quantity
             END
         END                               AS  qty            -- ����
        ,CASE
          WHEN ( (xic3v.item_class_code = gc_item_cd_prod) AND (xim2v.conv_unit IS NOT NULL) ) THEN
            xim2v.conv_unit
          ELSE
            xim2v.item_um
          END                              AS  qty_tani       -- �P��
      FROM
         xxwsh_order_headers_all          xoha      -- �󒍃w�b�_�A�h�I��
        ,xxwsh_oe_transaction_types2_v    xott2v    -- �󒍃^�C�v���VIEW2
        ,xxwsh_order_lines_all            xola      -- �󒍖��׃A�h�I��
        ,xxcmn_item_mst2_v                xim2v     -- OPM�i�ڏ��VIEW2
        ,xxcmn_item_categories3_v         xic3v     -- OPM�i�ڃJ�e�S���������VIEW3
        ,xxinv_mov_lot_details            xmld      -- �ړ����b�g�ڍ�(�A�h�I��)
        ,ic_lots_mst                      ilm       -- OPM���b�g�}�X�^
        ,xxcmn_item_locations2_v          xil2v     -- OPM�ۊǏꏊ���VIEW2
        ,xxcmn_cust_acct_sites2_v         xcas2v    -- �ڋq�T�C�g���VIEW2
        ,xxcmn_cust_accounts2_v           xca2v     -- �ڋq���VIEW2
        ,xxcmn_lookup_values2_v           xlv2v     -- �N�C�b�N�R�[�h���VIEW2
      WHERE
      -------------------------------------------------------------------------------
      -- �󒍃w�b�_�A�h�I��
      -------------------------------------------------------------------------------
             xoha.req_status  >=  gc_ship_status_close     -- ���ߍς�
        AND  xoha.req_status  <>  gc_ship_status_delete    -- ���
        AND  (gt_param.delivery_to IS NULL
          OR  xoha.deliver_to  =  gt_param.delivery_to
        )
        AND  (((gt_param.shipped_cd IS NULL) AND (gt_param.block IS NULL))
          OR  xoha.deliver_from         =  gt_param.shipped_cd
          OR  xil2v.distribution_block  =  gt_param.block
        )
        AND  xoha.schedule_ship_date    =  gt_param.shipped_date
        AND  xoha.latest_external_flag  =  gc_new_flg
        ------------------------------------------------
        -- �󒍃^�C�v���VIEW2
        ------------------------------------------------
        AND  xoha.order_type_id            =  xott2v.transaction_type_id
        AND  xott2v.shipping_shikyu_class  =  gc_req_kbn_ship     -- �o�׎x���敪'�o�׈˗�'
        AND  xott2v.order_category_code   <>  gc_order_cate_ret   -- �󒍃J�e�S��'�ԕi'
        AND  (gt_param.ship_type IS NULL
          OR  xott2v.transaction_type_id   =  gt_param.ship_type
        )
        -------------------------------------------------------------------------------
        -- �󒍖��׃A�h�I��
        -------------------------------------------------------------------------------
        AND  xoha.order_header_id   =  xola.order_header_id
        AND  xola.delete_flag      <>  gc_delete_flg
        -------------------------------------------------------------------------------
        -- OPM�i�ڏ��VIEW2
        -------------------------------------------------------------------------------
        AND  xola.shipping_inventory_item_id   = xim2v.inventory_item_id
        AND  xim2v.start_date_active          <= xoha.schedule_ship_date
        AND  (xim2v.end_date_active           >= xoha.schedule_ship_date
          OR  xim2v.end_date_active IS NULL
        )
        -------------------------------------------------------------------------------
        -- OPM�i�ڃJ�e�S���������VIEW3
        -------------------------------------------------------------------------------
        AND  xim2v.item_id            =  xic3v.item_id
        AND  (gt_param.item_class IS NULL
          OR  xic3v.item_class_code   =  gt_param.item_class
        )
        AND  xic3v.prod_class_code    =  gt_param.prod_class
        -------------------------------------------------------------------------------
        -- �ړ����b�g�ڍ�(�A�h�I��)
        -------------------------------------------------------------------------------
        AND  xola.order_line_id          =  xmld.mov_line_id(+)
        AND  xmld.document_type_code(+)  =  gc_doc_type_ship   -- �o�׈˗�
        AND  xmld.record_type_code(+)    =  gc_rec_type_shiji  -- �w��
        -------------------------------------------------------------------------------
        -- OPM���b�g�}�X�^
        -------------------------------------------------------------------------------
        AND  xmld.lot_id   =  ilm.lot_id(+)
        AND  xmld.item_id  =  ilm.item_id(+)
        -------------------------------------------------------------------------------
        -- �ڋq�T�C�g���VIEW2
        -------------------------------------------------------------------------------
        AND  xoha.deliver_to_id         =  xcas2v.party_site_id
        AND  xcas2v.start_date_active  <=  xoha.schedule_ship_date
        AND  (xcas2v.end_date_active   >=  xoha.schedule_ship_date
          OR  xcas2v.end_date_active IS NULL
        )
        -------------------------------------------------------------------------------
        -- �ڋq���VIEW2
        -------------------------------------------------------------------------------
        AND  xoha.head_sales_branch    =  xca2v.party_number
        AND  xca2v.start_date_active  <=  xoha.schedule_ship_date
        AND  (xca2v.end_date_active   >=  xoha.schedule_ship_date
          OR  xca2v.end_date_active IS NULL
        )
        -------------------------------------------------------------------------------
        -- OPM�ۊǏꏊ���VIEW2
        -------------------------------------------------------------------------------
        AND  xoha.deliver_from_id  =  xil2v.inventory_location_id
        -------------------------------------------------------------------------------
        -- �N�C�b�N�R�[�h���VIEW2
        -------------------------------------------------------------------------------
        AND  xlv2v.lookup_type  =  gc_lookup_cd_int_ext
        AND  xlv2v.lookup_code  =  xic3v.int_ext_class   -- ���Б��Ћ敪(1:���ЁA2:���Ёj
      ORDER BY
         trans_type_id       ASC   -- �o�Ɍ`��
        ,shipped_code        ASC   -- �o�Ɍ�(�R�[�h)
        ,item_class_code     ASC   -- �i�ڋ敪
        ,shipped_date        ASC   -- �o�ɓ�
        ,int_ext_class_code  ASC   -- ���O�敪�R�[�h
        ,item_code           ASC   -- �i�ڃR�[�h
        ,lot_no              ASC   -- ���b�gNo
        ,base_cd             ASC   -- �Ǌ����_�R�[�h
        ,delivery_to_code    ASC   -- �z����^���ɐ�R�[�h
        ,req_move_no         ASC   -- �˗�No�^�ړ�No
      ;
--
    ----------------------------------------------------------------------------------
    -- �x�����
    ----------------------------------------------------------------------------------
    CURSOR cur_data_supply
    IS
      SELECT
         TO_CHAR(gc_biz_type_nm_supply)    AS  biz_kind               -- �Ɩ����
        ,xoha.order_type_id                AS  trans_type_id          -- �o�Ɍ`��
        ,xott2v.transaction_type_name      AS  trans_type_name        -- �o�Ɍ`�Ԗ�
        ,xoha.deliver_from                 AS  shipped_code           -- �o�Ɍ��R�[�h
        ,xil2v.description                 AS  shipped_name           -- �o�Ɍ�����
        ,xic3v.item_class_code             AS  item_class_code        -- �i�ڋ敪�R�[�h
        ,xic3v.item_class_name             AS  item_class_name        -- �i�ڋ敪����
        ,xoha.schedule_ship_date           AS  shipped_date           -- �o�ɓ�
        ,xic3v.int_ext_class               AS  int_ext_class_code     -- ���O�敪�R�[�h
        ,xlv2v.meaning                     AS  int_ext_class_name     -- ���O�敪��
        ,xola.shipping_item_code           AS  item_code              -- �i�ڃR�[�h
        ,xim2v.item_short_name             AS  item_name              -- �i�ږ���
        ,xmld.lot_no                       AS  lot_no                 -- ���b�gNo
        ,ilm.attribute1                    AS  prod_date              -- ������
        ,ilm.attribute3                    AS  best_before_date       -- �ܖ�����
        ,ilm.attribute2                    AS  native_sign            -- �ŗL�L��
        ,xoha.vendor_code                  AS  base_cd                -- �Ǌ����_�R�[�h
        ,xv2v.vendor_short_name            AS  base_nm                -- �Ǌ����_����
        ,xoha.vendor_site_code             AS  delivery_to_code       -- �z����/���ɐ�R�[�h
        ,xvs2v.vendor_site_name            AS  delivery_to_name       -- �z����/���ɐ於��
        ,xoha.request_no                   AS  req_move_no            -- �˗�No
        ,xoha.schedule_arrival_date        AS  arrive_date            -- ����
        ,SUBSTRB(xoha.shipping_instructions, 1, 30) AS  description   -- �E�v
        ,CASE                                     
         -- ��������Ă���ꍇ
         WHEN ( xola.reserved_quantity > 0 ) THEN
           xmld.actual_quantity
         -- ��������Ă��Ȃ��ꍇ
         WHEN  ( ( xola.reserved_quantity IS NULL ) OR ( xola.reserved_quantity = 0 ) ) THEN
           xola.quantity
         END                               AS  qty            -- ����
        ,xim2v.item_um                     AS  qty_tani       -- �P��
      FROM
         xxwsh_order_headers_all         xoha       -- �󒍃w�b�_�A�h�I��
        ,xxwsh_oe_transaction_types2_v   xott2v     -- �󒍃^�C�v���VIEW2
        ,xxwsh_order_lines_all           xola       -- �󒍖��׃A�h�I��
        ,xxcmn_item_mst2_v               xim2v      -- OPM�i�ڏ��VIEW2
        ,xxcmn_item_categories3_v        xic3v      -- OPM�i�ڃJ�e�S���������VIEW3
        ,xxinv_mov_lot_details           xmld       -- �ړ����b�g�ڍ�(�A�h�I��)
        ,ic_lots_mst                     ilm        -- OPM���b�g�}�X�^
        ,xxcmn_item_locations2_v         xil2v      -- OPM�ۊǏꏊ���VIEW2
        ,xxcmn_vendor_sites2_v           xvs2v      -- �d����T�C�g���VIEW2
        ,xxcmn_vendors2_v                xv2v       -- �d������VIEW2
        ,xxcmn_lookup_values2_v          xlv2v      -- �N�C�b�N�R�[�h���VIEW2
      WHERE
        -------------------------------------------------------------------------------
        -- �󒍃w�b�_�A�h�I��
        -------------------------------------------------------------------------------
             xoha.req_status  >=  gc_ship_status_receipt  -- ��̍�
        AND  xoha.req_status  <>  gc_ship_status_delete   -- ���
        AND  (gt_param.delivery_to IS NULL
             --Mod start 2008/06/24 uehara
--          OR  xoha.deliver_to = gt_param.delivery_to
          OR  xoha.vendor_site_code = gt_param.delivery_to
             --Mod end 2008/06/24 uehara
        )
        AND  ((gt_param.shipped_cd IS NULL) AND  (gt_param.block IS NULL)
          OR  xoha.deliver_from         =  gt_param.shipped_cd
          OR  xil2v.distribution_block  =  gt_param.block
        )
        AND  xoha.schedule_ship_date    = gt_param.shipped_date
        AND  xoha.latest_external_flag  = gc_new_flg
        ------------------------------------------------
        -- �󒍃^�C�v���VIEW2
        ------------------------------------------------
        AND  xoha.order_type_id            =  xott2v.transaction_type_id
        AND  xott2v.shipping_shikyu_class  =  gc_req_kbn_supply    -- �o�׎x���敪'�x���˗�'
        AND  xott2v.order_category_code   <>  gc_order_cate_ret    -- �󒍃J�e�S��'�ԕi'
        AND  (gt_param.ship_type IS NULL
          OR  xott2v.transaction_type_id  =  gt_param.ship_type
        )
        -------------------------------------------------------------------------------
        -- �󒍖��׃A�h�I��
        -------------------------------------------------------------------------------
        AND  xoha.order_header_id   =  xola.order_header_id
        AND  xola.delete_flag      <>  gc_delete_flg
        -------------------------------------------------------------------------------
        -- OPM�i�ڏ��VIEW2
        -------------------------------------------------------------------------------
        AND  xola.shipping_inventory_item_id  =  xim2v.inventory_item_id
        AND  xim2v.start_date_active  <=  xoha.schedule_ship_date
        AND  (xim2v.end_date_active   >=  xoha.schedule_ship_date
          OR  xim2v.end_date_active IS NULL
        )
        -------------------------------------------------------------------------------
        -- OPM�i�ڃJ�e�S���������VIEW3
        -------------------------------------------------------------------------------
        AND  xim2v.item_id           =  xic3v.item_id
        AND  xic3v.prod_class_code   =  gt_param.prod_class
        AND  (gt_param.item_class IS NULL
          OR  xic3v.item_class_code  =  gt_param.item_class
        )
        -------------------------------------------------------------------------------
        -- �ړ����b�g�ڍ�(�A�h�I��)
        -------------------------------------------------------------------------------
        AND  xola.order_line_id          =  xmld.mov_line_id(+)
        AND  xmld.document_type_code(+)  =  gc_doc_type_supply  -- �x���w��
        AND  xmld.record_type_code(+)    =  gc_rec_type_shiji   -- �w��
        -------------------------------------------------------------------------------
        -- OPM���b�g�}�X�^
        -------------------------------------------------------------------------------
        AND  xmld.lot_id   =  ilm.lot_id(+)
        AND  xmld.item_id  =  ilm.item_id(+)
        -------------------------------------------------------------------------------
        -- �d����T�C�g���VIEW2
        -------------------------------------------------------------------------------
        AND  xoha.vendor_site_id       = xvs2v.vendor_site_id
        AND  xvs2v.start_date_active  <= xoha.schedule_ship_date
        AND  (xvs2v.end_date_active   >= xoha.schedule_ship_date
          OR  xvs2v.end_date_active IS NULL
        )
        -------------------------------------------------------------------------------
        -- �d������VIEW2
        -------------------------------------------------------------------------------
        AND  xoha.vendor_id           = xv2v.vendor_id
        AND  xv2v.start_date_active  <= xoha.schedule_ship_date
        AND  (xv2v.end_date_active   >= xoha.schedule_ship_date
          OR  xv2v.end_date_active IS NULL
        )
        -------------------------------------------------------------------------------
        -- OPM�ۊǏꏊ���VIEW2
        -------------------------------------------------------------------------------
        AND  xoha.deliver_from_id  =  xil2v.inventory_location_id
        -------------------------------------------------------------------------------
        -- �N�C�b�N�R�[�h���VIEW2
        -------------------------------------------------------------------------------
        AND  xlv2v.lookup_type  =  gc_lookup_cd_int_ext
        AND  xlv2v.lookup_code  =  xic3v.int_ext_class    -- ���Б��Ћ敪(1:���ЁA2:���Ёj
      ORDER BY
         trans_type_id       ASC   -- �o�Ɍ`��
        ,shipped_code        ASC   -- �o�Ɍ�(�R�[�h)
        ,item_class_code     ASC   -- �i�ڋ敪
        ,shipped_date        ASC   -- �o�ɓ�
        ,int_ext_class_code  ASC   -- ���O�敪�R�[�h
        ,item_code           ASC   -- �i�ڃR�[�h
        ,lot_no              ASC   -- ���b�gNo
        ,base_cd             ASC   -- �Ǌ����_�R�[�h
        ,delivery_to_code    ASC   -- �z����^���ɐ�R�[�h
        ,req_move_no         ASC   -- �˗�No�^�ړ�No
      ;
--
    ----------------------------------------------------------------------------------
    -- �ړ����
    ----------------------------------------------------------------------------------
    CURSOR cur_data_move
    IS
      SELECT
         TO_CHAR(gc_biz_type_nm_move)      AS  biz_kind               -- �Ɩ����
        ,NULL                              AS  trans_type_id          -- �o�Ɍ`��
        ,NULL                              AS  trans_type_name        -- �o�Ɍ`�Ԗ�
        ,xmrih.shipped_locat_code          AS  shipped_code           -- �o�Ɍ��R�[�h
        ,xil2v1.description                AS  shipped_name           -- �o�Ɍ�����
        ,xic3v.item_class_code             AS  item_class_code        -- �i�ڋ敪�R�[�h
        ,xic3v.item_class_name             AS  item_class_name        -- �i�ڋ敪����
        ,xmrih.schedule_ship_date          AS  shipped_date           -- �o�ɓ�
        ,xic3v.int_ext_class               AS  int_ext_class_code     -- ���O�敪�R�[�h
        ,xlv2v.meaning                     AS  int_ext_class_name     -- ���O�敪��
        ,xmril.item_code                   AS  item_code              -- �i�ڃR�[�h
        ,xim2v.item_short_name             AS  item_name              -- �i�ږ���
        ,xmld.lot_no                       AS  lot_no                 -- ���b�gNo
        ,ilm.attribute1                    AS  prod_date              -- ������
        ,ilm.attribute3                    AS  best_before_date       -- �ܖ�����
        ,ilm.attribute2                    AS  native_sign            -- �ŗL�L��
        ,NULL                              AS  base_cd                -- �Ǌ����_�R�[�h
        ,NULL                              AS  base_nm                -- �Ǌ����_����
        ,xmrih.ship_to_locat_code          AS  delivery_to_code       -- �z����/���ɐ�R�[�h
        ,xil2v2.description                AS  delivery_to_name       -- �z����/���ɐ於��
        ,xmrih.mov_num                     AS  req_move_no            -- �˗�No
        ,xmrih.schedule_arrival_date       AS  arrive_date            -- ����
        ,SUBSTRB(xmrih.description, 1, 30) AS  description            -- �E�v
        ,CASE
         -- ��������Ă���ꍇ
         WHEN ( xmril.reserved_quantity > 0 ) THEN
           CASE 
             WHEN  (xic3v.prod_class_code = gc_prod_cd_drink
               AND  xic3v.item_class_code = gc_item_cd_prod
               AND  xim2v.conv_unit IS NOT NULL ) THEN
               xmld.actual_quantity / TO_NUMBER(
                                        CASE
                                          WHEN ( xim2v.num_of_cases > 0 ) THEN
                                            xim2v.num_of_cases
                                          ELSE
                                            TO_CHAR(1)
                                        END
                                      )
             ELSE
               xmld.actual_quantity
             END
         -- ��������Ă��Ȃ��ꍇ
         WHEN  ( (xmril.reserved_quantity IS NULL) OR (xmril.reserved_quantity = 0) ) THEN
           CASE 
             WHEN  (xic3v.prod_class_code = gc_prod_cd_drink
               AND  xic3v.item_class_code = gc_item_cd_prod
               AND  xim2v.conv_unit IS NOT NULL ) THEN
               xmril.instruct_qty / TO_NUMBER(
                                      CASE
                                        WHEN ( xim2v.num_of_cases > 0 ) THEN
                                          xim2v.num_of_cases
                                        ELSE
                                          TO_CHAR(1)
                                      END
                                    )
             ELSE
               xmril.instruct_qty
             END
         END                               AS  qty            -- ����
        ,CASE
          WHEN  (xic3v.prod_class_code = gc_prod_cd_drink
            AND  xic3v.item_class_code = gc_item_cd_prod
            AND  xim2v.conv_unit IS NOT NULL ) THEN
            xim2v.conv_unit
          ELSE
            xim2v.item_um
          END                              AS  qty_tani       -- �P��
      FROM
         xxinv_mov_req_instr_headers   xmrih      -- �ړ��˗�/�w���w�b�_�A�h�I��
        ,xxinv_mov_req_instr_lines     xmril      -- �ړ��˗�/�w������(�A�h�I��)
        ,xxcmn_item_mst2_v             xim2v      -- OPM�i�ڏ��VIEW2
        ,xxcmn_item_categories3_v      xic3v      -- OPM�i�ڃJ�e�S���������VIEW3
        ,xxinv_mov_lot_details         xmld       -- �ړ����b�g�ڍ�(�A�h�I��)
        ,ic_lots_mst                   ilm        -- OPM���b�g�}�X�^
        ,xxcmn_item_locations2_v       xil2v1     -- OPM�ۊǏꏊ���VIEW2-1
        ,xxcmn_item_locations2_v       xil2v2     -- OPM�ۊǏꏊ���VIEW2-2
        ,xxcmn_lookup_values2_v        xlv2v      -- �N�C�b�N�R�[�h���VIEW2
      WHERE
        -------------------------------------------------------------------------------
        -- �ړ��˗�/�w���w�b�_�A�h�I��
        -------------------------------------------------------------------------------
             xmrih.mov_type  <>  gc_mov_type_not_ship      -- �ϑ��Ȃ�
        AND  xmrih.status    >=  gc_move_status_ordered    -- �˗���
        AND  xmrih.status    <>  gc_move_status_delete     -- ���
        AND  (gt_param.delivery_to IS NULL
          OR  xmrih.ship_to_locat_code  =  gt_param.delivery_to
        )
        AND  ( ((gt_param.shipped_cd IS NULL) AND (gt_param.block IS NULL))
          OR  xmrih.shipped_locat_code   =  gt_param.shipped_cd
          OR  xil2v1.distribution_block  =  gt_param.block
        )
        AND  xmrih.schedule_ship_date  =  gt_param.shipped_date
        -------------------------------------------------------------------------------
        -- �ړ��˗�/�w������(�A�h�I��)
        -------------------------------------------------------------------------------
        AND  xmrih.mov_hdr_id   =  xmril.mov_hdr_id
        AND  xmril.delete_flg  <>  gc_delete_flg
        -------------------------------------------------------------------------------
        -- OPM�i�ڏ��VIEW2
        -------------------------------------------------------------------------------
        AND  xmril.item_id             =  xim2v.item_id
        AND  xim2v.start_date_active  <=  xmrih.schedule_ship_date
        AND  (xim2v.end_date_active IS NULL
          OR  xim2v.end_date_active   >=  xmrih.schedule_ship_date
        )
        -------------------------------------------------------------------------------
        -- OPM�i�ڃJ�e�S���������VIEW3
        -------------------------------------------------------------------------------
        AND  xim2v.item_id           =  xic3v.item_id
        AND  xic3v.prod_class_code   =  gt_param.prod_class
        AND  (gt_param.item_class IS NULL
          OR  xic3v.item_class_code  =  gt_param.item_class
        )
        -------------------------------------------------------------------------------
        -- �ړ����b�g�ڍ�(�A�h�I��)
        -------------------------------------------------------------------------------
        AND  xmril.mov_line_id           =  xmld.mov_line_id(+)
        AND  xmld.document_type_code(+)  =  gc_doc_type_move   -- ���̓^�C�v:�ړ�
        AND  xmld.record_type_code(+)    =  gc_rec_type_shiji  -- ���R�[�h�^�C�v:�w��
        -------------------------------------------------------------------------------
        -- OPM���b�g�}�X�^
        -------------------------------------------------------------------------------
        AND  xmld.lot_id   = ilm.lot_id(+)
        AND  xmld.item_id  = ilm.item_id(+)
        -------------------------------------------------------------------------------
        -- OPM�ۊǏꏊ���VIEW2-1
        -------------------------------------------------------------------------------
        AND  xmrih.shipped_locat_id  =  xil2v1.inventory_location_id
        -------------------------------------------------------------------------------
        -- OPM�ۊǏꏊ���VIEW2-2
        -------------------------------------------------------------------------------
        AND  xmrih.ship_to_locat_id  =  xil2v2.inventory_location_id
        -------------------------------------------------------------------------------
        -- �N�C�b�N�R�[�h���VIEW2
        -------------------------------------------------------------------------------
        AND  xlv2v.lookup_type  =  gc_lookup_cd_int_ext
        AND  xlv2v.lookup_code  =  xic3v.int_ext_class       -- ���Б��Ћ敪(1:���ЁA2:���Ёj
      ORDER BY
         shipped_code        ASC   -- �o�Ɍ�(�R�[�h)
        ,item_class_code     ASC   -- �i�ڋ敪
        ,shipped_date        ASC   -- �o�ɓ�
        ,int_ext_class_code  ASC   -- ���O�敪�R�[�h
        ,item_code           ASC   -- �i�ڃR�[�h
        ,lot_no              ASC   -- ���b�gNo
        ,base_cd             ASC   -- �Ǌ����_�R�[�h
        ,delivery_to_code    ASC   -- �z����^���ɐ�R�[�h
        ,req_move_no         ASC   -- �˗�No�^�ړ�No
      ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���[�UID���擾���A�ϐ��Ɋi�[
    gv_user_id := FND_GLOBAL.USER_ID ;
--
    -- ====================================================
    -- �S���ҏ��擾
    -- ====================================================
    -- �S������
    gv_dept_cd := SUBSTRB(xxcmn_common_pkg.get_user_dept(gv_user_id), 1, 10) ;
    -- �S����
    gv_dept_nm := SUBSTRB(xxcmn_common_pkg.get_user_name(gv_user_id), 1, 14) ;
--
    -- ====================================================
    -- ���[�f�[�^�擾
    -- ====================================================
    ------------------------------
    -- �Ɩ���ʂ��u�o�ׁv�̏ꍇ
    ------------------------------
    IF (gt_param.biz_type = gc_biz_type_cd_ship) THEN
      -- ���[�f�[�^�擾
      OPEN  cur_data_ship ;
      FETCH cur_data_ship BULK COLLECT INTO gt_report_data ;
      CLOSE cur_data_ship ;
--
      -- �Ɩ���ʖ���ݒ�
      gv_biz_type_nm := gc_biz_type_nm_ship ;
--
    ------------------------------
    -- �Ɩ���ʂ��u�x���v�̏ꍇ
    ------------------------------
    ELSIF (gt_param.biz_type = gc_biz_type_cd_supply) THEN
      -- ���[�f�[�^�擾
      OPEN  cur_data_supply ;
      FETCH cur_data_supply BULK COLLECT INTO gt_report_data ;
      CLOSE cur_data_supply ;
--
      -- �Ɩ���ʖ���ݒ�
      gv_biz_type_nm := gc_biz_type_nm_supply ;
--
    ------------------------------
    -- �Ɩ���ʂ��u�ړ��v�̏ꍇ
    ------------------------------
    ELSIF (gt_param.biz_type = gc_biz_type_cd_move) THEN
      -- ���[�f�[�^�擾
      OPEN  cur_data_move ;
      FETCH cur_data_move BULK COLLECT INTO gt_report_data ;
      CLOSE cur_data_move ;
--
      -- �Ɩ���ʖ���ݒ�
      gv_biz_type_nm := gc_biz_type_nm_move ;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( cur_data_ship%ISOPEN ) THEN
        CLOSE cur_data_ship ;
      END IF ;
      IF ( cur_data_supply%ISOPEN ) THEN
        CLOSE cur_data_supply ;
      END IF ;
      IF ( cur_data_move%ISOPEN ) THEN
        CLOSE cur_data_move ;
      END IF ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( cur_data_ship%ISOPEN ) THEN
        CLOSE cur_data_ship ;
      END IF ;
      IF ( cur_data_supply%ISOPEN ) THEN
        CLOSE cur_data_supply ;
      END IF ;
      IF ( cur_data_move%ISOPEN ) THEN
        CLOSE cur_data_move ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( cur_data_ship%ISOPEN ) THEN
        CLOSE cur_data_ship ;
      END IF ;
      IF ( cur_data_supply%ISOPEN ) THEN
        CLOSE cur_data_supply ;
      END IF ;
      IF ( cur_data_move%ISOPEN ) THEN
        CLOSE cur_data_move ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_report_data;
--
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
    lv_tmp_trans_type      type_report_data.trans_type_id%TYPE DEFAULT NULL ;   -- �o�Ɍ`��
    lv_tmp_ship_cd         type_report_data.shipped_code%TYPE DEFAULT NULL ;    -- �o�Ɍ�
    lv_tmp_item_class      type_report_data.item_class_code%TYPE DEFAULT NULL ; -- �i�ڋ敪
    lv_tmp_ship_date       type_report_data.shipped_date%TYPE DEFAULT NULL ;    -- �o�ɓ�
    lv_tmp_lot_no          type_report_data.lot_no%TYPE DEFAULT NULL ;          -- ���b�gNo
    lv_tmp_item_code       type_report_data.item_code%TYPE DEFAULT NULL ;       -- �i�ڃR�[�h 2008/07/10 Fukuda Add
--
    -- �^�O�o�͔���t���O
    lb_dispflg_trans_type  BOOLEAN DEFAULT TRUE ;       -- �o�Ɍ`��
    lb_dispflg_ship_cd     BOOLEAN DEFAULT TRUE ;       -- �o�Ɍ�
    lb_dispflg_item_class  BOOLEAN DEFAULT TRUE ;       -- �i�ڋ敪
    lb_dispflg_ship_date   BOOLEAN DEFAULT TRUE ;       -- �o�ɓ�
    lb_dispflg_lot_no      BOOLEAN DEFAULT TRUE ;       -- ���b�gNo
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
    prc_set_tag_data('biz_kind', gv_biz_type_nm);
    prc_set_tag_data('lg_trans_type_info') ;
--
    -- -----------------------------------------------------
    -- ���[0���pXML�f�[�^�쐬
    -- -----------------------------------------------------
    IF (gt_report_data.COUNT = 0) THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg(gc_application_cmn, gc_msg_id_no_data) ;
--
      prc_set_tag_data('g_trans_type_info') ;
      prc_set_tag_data('lg_ship_cd_info') ;
      prc_set_tag_data('g_ship_cd_info') ;
      prc_set_tag_data('lg_item_class_info') ;
      prc_set_tag_data('g_item_class_info') ;
      prc_set_tag_data('lg_ship_date_info') ;
      prc_set_tag_data('g_ship_date_info') ;
      prc_set_tag_data('lg_lot_no_info') ;
      prc_set_tag_data('g_lot_no_info') ;
      prc_set_tag_data('msg', ov_errmsg) ;
      prc_set_tag_data('/g_lot_no_info') ;
      prc_set_tag_data('/lg_lot_no_info') ;
      prc_set_tag_data('/g_ship_date_info') ;
      prc_set_tag_data('/lg_ship_date_info') ;
      prc_set_tag_data('/g_item_class_info') ;
      prc_set_tag_data('/lg_item_class_info') ;
      prc_set_tag_data('/g_ship_cd_info') ;
      prc_set_tag_data('/lg_ship_cd_info') ;
      prc_set_tag_data('/g_trans_type_info') ;
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
      -- �o�Ɍ`�ԃO���[�v
      IF (lb_dispflg_trans_type) THEN
        prc_set_tag_data('g_trans_type_info') ;
        prc_set_tag_data('trans_type', gt_report_data(i).trans_type_name) ;
        prc_set_tag_data('lg_ship_cd_info') ;
      END IF ;
--
      -- �o�Ɍ��O���[�v
      IF (lb_dispflg_ship_cd) THEN
        prc_set_tag_data('g_ship_cd_info') ;
        prc_set_tag_data('ship_cd', gt_report_data(i).shipped_code) ;
        prc_set_tag_data('ship_nm', gt_report_data(i).shipped_name) ;
        prc_set_tag_data('lg_item_class_info') ;
      END IF ;
--
      -- �i�ڋ敪�O���[�v
      IF (lb_dispflg_item_class) THEN
        prc_set_tag_data('g_item_class_info') ;
        prc_set_tag_data('item_class', gt_report_data(i).item_class_name) ;
        prc_set_tag_data('lg_ship_date_info') ;
      END IF ;
--
      -- �o�ɓ��O���[�v
      IF (lb_dispflg_ship_date) THEN
        prc_set_tag_data('g_ship_date_info') ;
        prc_set_tag_data('ship_date', fnc_chgdt_c(gt_report_data(i).shipped_date)) ;
        prc_set_tag_data('lg_lot_no_info') ;
      END IF ;
--
      -- ���b�gNo�O���[�v
      IF (lb_dispflg_lot_no) THEN
        prc_set_tag_data('g_lot_no_info') ;
        prc_set_tag_data('int_ext_class', gt_report_data(i).int_ext_class_name) ;
        prc_set_tag_data('item_cd', gt_report_data(i).item_code) ;
        prc_set_tag_data('item_nm', gt_report_data(i).item_name) ;
        prc_set_tag_data('lot_no', gt_report_data(i).lot_no) ;
        prc_set_tag_data('prod_date', gt_report_data(i).prod_date) ;
        prc_set_tag_data('best_before_date', gt_report_data(i).best_before_date) ;
        prc_set_tag_data('native_sign', gt_report_data(i).native_sign) ;
        prc_set_tag_data('lg_dtl_info') ;
      END IF ;
--
      -- ���׃O���[�v
      prc_set_tag_data('g_dtl_info') ;
      prc_set_tag_data('base_nm', gt_report_data(i).base_nm) ;
      prc_set_tag_data('delivery_to_nm', gt_report_data(i).delivery_to_name) ;
      prc_set_tag_data('req_move_no', gt_report_data(i).req_move_no) ;
      prc_set_tag_data('arrive_date', fnc_chgdt_c(gt_report_data(i).arrive_date)) ;
      prc_set_tag_data('description', gt_report_data(i).description) ;
      prc_set_tag_data('qty', gt_report_data(i).qty) ;
      prc_set_tag_data('qty_tani', gt_report_data(i).qty_tani) ;
      prc_set_tag_data('/g_dtl_info') ;
--
      -- ====================================================
      -- ���ݏ������̃f�[�^��ێ�
      -- ====================================================
      lv_tmp_trans_type   :=  gt_report_data(i).trans_type_id ;     -- �o�Ɍ`��
      lv_tmp_ship_cd      :=  gt_report_data(i).shipped_code ;      -- �o�Ɍ�
      lv_tmp_item_class   :=  gt_report_data(i).item_class_code ;   -- �i�ڋ敪
      lv_tmp_ship_date    :=  gt_report_data(i).shipped_date ;      -- �o�ɓ�
      lv_tmp_lot_no       :=  gt_report_data(i).lot_no ;            -- ���b�gNo
      lv_tmp_item_code    :=  gt_report_data(i).item_code ;         -- �i�ڃR�[�h 2008/07/10 Fukuda Add
--
      -- ====================================================
      -- �o�͔���
      -- ====================================================
      IF (i < gt_report_data.COUNT) THEN
        -- ���b�gNo
  -- 2008/08/05 v1.4 UPDATE START
/*        -- 2008/07/10 Fukuda Start �i�ڂ�����Ă����b�gNo.��NULL���ƈꊇ��ŏo�͂���Ă��܂�
        --IF ( (lv_tmp_lot_no = gt_report_data(i + 1).lot_no)
        --  OR ((lv_tmp_lot_no IS NULL) AND (gt_report_data(i + 1).lot_no IS NULL)) ) THEN
        IF (lv_tmp_lot_no = gt_report_data(i + 1).lot_no)
          AND (lv_tmp_item_code = gt_report_data(i + 1).item_code) THEN
*/        -- 2008/07/10 Fukuda End
        -- �i�ڃR�[�h�������A�����b�gNo.���������݂���NULL�̏ꍇ
        IF (
             (lv_tmp_item_code = gt_report_data(i + 1).item_code)
               AND (
                     (lv_tmp_lot_no = gt_report_data(i + 1).lot_no)
                     OR
                     (
                       (lv_tmp_lot_no IS NULL)
                         AND (gt_report_data(i + 1).lot_no IS NULL)
                     )
                   )
           ) THEN
-- 2008/08/05 v1.4 UPDATE END
          lb_dispflg_lot_no := FALSE ;
        ELSE
          lb_dispflg_lot_no := TRUE ;
        END IF ;
--
        -- �o�ɓ�
        IF (lv_tmp_ship_date = gt_report_data(i + 1).shipped_date) THEN
          lb_dispflg_ship_date := FALSE ;
        ELSE
          lb_dispflg_ship_date := TRUE ;
          lb_dispflg_lot_no    := TRUE ;
        END IF ;
--
        -- �i�ڋ敪
        IF (lv_tmp_item_class = gt_report_data(i + 1).item_class_code) THEN
          lb_dispflg_item_class := FALSE ;
        ELSE
          lb_dispflg_item_class := TRUE ;
          lb_dispflg_ship_date  := TRUE ;
          lb_dispflg_lot_no     := TRUE ;
        END IF ;
--
        -- �o�Ɍ�
        IF (lv_tmp_ship_cd = gt_report_data(i + 1).shipped_code) THEN
          lb_dispflg_ship_cd := FALSE ;
        ELSE
          lb_dispflg_ship_cd    := TRUE ;
          lb_dispflg_item_class := TRUE ;
          lb_dispflg_ship_date  := TRUE ;
          lb_dispflg_lot_no     := TRUE ;
        END IF ;
--
        -- �o�Ɍ`��
        IF ( (lv_tmp_trans_type = gt_report_data(i + 1).trans_type_id)
          OR ((lv_tmp_trans_type IS NULL) AND (gt_report_data(i + 1).trans_type_id IS NULL)) ) THEN
          lb_dispflg_trans_type := FALSE ;
        ELSE
          lb_dispflg_trans_type := TRUE ;
          lb_dispflg_ship_cd    := TRUE ;
          lb_dispflg_item_class := TRUE ;
          lb_dispflg_ship_date  := TRUE ;
          lb_dispflg_lot_no     := TRUE ;
        END IF ;
--
      ELSE
          lb_dispflg_trans_type := TRUE ;
          lb_dispflg_ship_cd    := TRUE ;
          lb_dispflg_item_class := TRUE ;
          lb_dispflg_ship_date  := TRUE ;
          lb_dispflg_lot_no     := TRUE ;
      END IF;
--
      -- ====================================================
      -- �I���^�O�ݒ�
      -- ====================================================
      -- ���b�gNo
      IF (lb_dispflg_lot_no) THEN
        prc_set_tag_data('/lg_dtl_info') ;
        prc_set_tag_data('/g_lot_no_info') ;
      END IF;
--
      -- �o�ɓ�
      IF (lb_dispflg_ship_date) THEN
        prc_set_tag_data('/lg_lot_no_info') ;
        prc_set_tag_data('/g_ship_date_info') ;
      END IF;
--
      -- �i�ڋ敪
      IF (lb_dispflg_item_class) THEN
        prc_set_tag_data('/lg_ship_date_info') ;
        prc_set_tag_data('/g_item_class_info') ;
      END IF;
--
      -- �o�Ɍ�
      IF (lb_dispflg_ship_cd) THEN
        prc_set_tag_data('/lg_item_class_info') ;
        prc_set_tag_data('/g_ship_cd_info') ;
      END IF;
--
      -- �o�Ɍ`��
      IF (lb_dispflg_trans_type) THEN
        prc_set_tag_data('/lg_ship_cd_info') ;
        prc_set_tag_data('/g_trans_type_info') ;
      END IF;
--
    END LOOP set_data_loop;
--
    -- ====================================================
    -- �I���^�O�ݒ�
    -- ====================================================
    prc_set_tag_data('/lg_trans_type_info') ;
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
      lv_data := '<'|| ir_xml.tag_name || '><![CDATA[' || ir_xml.tag_value || ']]></' || ir_xml.tag_name || '>';
    ELSE
      lv_data := '<' || ir_xml.tag_name || '>';
    END IF ;
--
    RETURN(lv_data);
--
  END fnc_convert_into_xml;
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
    ,iv_biz_type            IN     VARCHAR2      -- 01:�Ɩ����  ���K�{
    ,iv_ship_type           IN     VARCHAR2      -- 02:�o�Ɍ`��
    ,iv_block               IN     VARCHAR2      -- 03:�u���b�N
    ,iv_shipped_cd          IN     VARCHAR2      -- 04:�o�Ɍ�
    ,iv_delivery_to         IN     VARCHAR2      -- 05:�z����^���ɐ�
    ,iv_prod_class          IN     VARCHAR2      -- 06:���i�敪  ���K�{
    ,iv_item_class          IN     VARCHAR2      -- 07:�i�ڋ敪
    ,iv_shipped_date        IN     VARCHAR2      -- 08:�o�ɓ�    ���K�{
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
    gt_param.biz_type      :=  iv_biz_type ;                      -- 01:�Ɩ����  ���K�{
    gt_param.ship_type     :=  iv_ship_type ;                     -- 02:�o�Ɍ`��
    gt_param.block         :=  iv_block ;                         -- 03:�u���b�N
    gt_param.shipped_cd    :=  iv_shipped_cd ;                    -- 04:�o�Ɍ�
    gt_param.delivery_to   :=  iv_delivery_to ;                   -- 05:�z����^���ɐ�
    gt_param.prod_class    :=  iv_prod_class ;                    -- 06:���i�敪  ���K�{
    gt_param.item_class    :=  iv_item_class ;                    -- 07:�i�ڋ敪
    gt_param.shipped_date  :=  fnc_chgdt_d(iv_shipped_date) ;     -- 08:�o�ɓ�    ���K�{
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
END xxwsh620007c;
/
