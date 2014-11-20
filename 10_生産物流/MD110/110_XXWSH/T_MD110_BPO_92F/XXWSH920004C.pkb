CREATE OR REPLACE PACKAGE BODY xxwsh920004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name     : xxwsh920004c(body)
 * Description      : �o�׍w���˗��ꗗ
 * MD.050/070       : ���Y�������ʁi�o�ׁE�ړ��������jIssue1.0 (T_MD050_BPO_921)
 *                    ���Y�������ʁi�o�ׁE�ړ��������jIssue1.0 (T_MD070_BPO_92F)
 * Version          : 1.3
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  convert_into_xml          XML�f�[�^�ϊ�
 *  insert_xml_plsql_table    XML�f�[�^�i�[
 *  prc_initialize            �O����(D-1)
 *  prc_get_report_data       ���׃f�[�^�擾(D-2)
 *  prc_create_xml_data       �w�l�k�f�[�^�쐬(D-3)
 *  submain                   ���C�������v���V�[�W��
 *  main                      �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ------------------ -------------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -------------------------------------------------
 *  2008/03/25    1.0   Yoshitomo Kawasaki �V�K�쐬
 *  2008/06/11    1.1   Kazuo Kumamoto     �����ύX�v��#131�Ή�
 *  2008/07/08    1.2   Satoshi Yunba      �֑������Ή�
 *  2008/11/19    1.3   Takao Ohashi       �w�E623,663,665�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal             CONSTANT VARCHAR2(1)   := '0' ;
  gv_status_warn               CONSTANT VARCHAR2(1)   := '1' ;
  gv_status_error              CONSTANT VARCHAR2(1)   := '2' ;
  gv_msg_part                  CONSTANT VARCHAR2(3)   := ' : ' ;
  gv_msg_cont                  CONSTANT VARCHAR2(3)   := '.';
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
--
  -- ======================================================
  -- ���[�U�[�錾��
  -- ======================================================
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �p�b�P�[�W��
  gv_pkg_name                  CONSTANT VARCHAR2(20)  := 'xxwsh920004c';
  -- ���[ID
  gc_report_id                 CONSTANT VARCHAR2(12)  := 'XXWSH920004T';
  -- �o�̓^�O�^�C�v�iT�F�^�O�j
  gc_tag_type_tag              CONSTANT VARCHAR2(1)   := 'T' ;
  -- �o�̓^�O�^�C�v�iD�F�f�[�^�j
  gc_tag_type_data             CONSTANT VARCHAR2(1)   := 'D' ;
  -- �o�̓^�C�v�iC�FChar�j
  gc_tag_value_type_char       CONSTANT VARCHAR2(1)   := 'C' ;
--
  ------------------------------
  -- �N�C�b�N�R�[�h�֘A
  ------------------------------
  gc_final_unit_price_entered  CONSTANT VARCHAR2(1)   := 'Y' ;
  gc_lookup_cd_conreq          CONSTANT VARCHAR2(30)  := 'XXPO_AUTHORIZATION_STATUS' ;
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  -- �A�v���P�[�V�����iXXCMN�j
  gc_application_cmn           CONSTANT VARCHAR2(5)   := 'XXCMN' ;
  -- �A�v���P�[�V�����iXXPO�j
  gc_application_po            CONSTANT VARCHAR2(5)   := 'XXPO' ;
  -- �S�����������擾���b�Z�[�W
  gc_xxpo_00036                CONSTANT VARCHAR2(14)  := 'APP-XXPO-00036' ;
  -- �S���Җ����擾���b�Z�[�W
  gc_xxpo_00026                CONSTANT VARCHAR2(14)  := 'APP-XXPO-00026' ;
  -- �f�[�^���擾���b�Z�[�W
  gc_xxpo_00033                CONSTANT VARCHAR2(14)  := 'APP-XXPO-00033' ;
  -- ����0���p���b�Z�[�W
  gc_xxcmn_10122               CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10122' ;
  -- ���t�Ó����G���[���b�Z�[�W
  gc_xxwip_10016               CONSTANT VARCHAR2(15)  := 'APP-XXWIP-10016' ;
  -- �����X�e�[�^�X
  gc_order_status_req_making   CONSTANT VARCHAR2(2)   := '10' ;  -- �˗��쐬��
  gc_order_status_ordered      CONSTANT VARCHAR2(2)   := '15' ;  -- ������
  -- �o�׈˗��X�e�[�^�X
  gc_ship_status_delete        CONSTANT VARCHAR2(2)   := '99' ;  -- ���
  -- �ړ��X�e�[�^�X
  gc_mov_status_delete         CONSTANT VARCHAR2(2)   := '99' ;  -- ���
  -- ����t���O
  gc_cancelled_flg             CONSTANT VARCHAR2(1)   := 'Y'  ;  -- ����t���O
  -- �폜�t���O
  gc_delete_flag               CONSTANT VARCHAR2(1)   := 'Y'  ;  -- �폜�t���O
  -- �폜(�ړ�)�t���O
  gc_delete_mov_flag           CONSTANT VARCHAR2(1)   := 'Y'  ;  -- �폜(�ړ�)�t���O
  -- �ŐV�t���O
  gc_new_flg                   CONSTANT VARCHAR2(1)   := 'Y'  ;  -- �ŐV�t���O
  -- �o�׎x���敪
  gc_ship_pro_kbn_i            CONSTANT VARCHAR2(1)   := '1'  ;  -- �o�׈˗�
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  -- �N�����t�H�[�}�b�g
  gc_char_d_format             CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD' ;
  gc_char_dt_format            CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS' ;
  gc_date_fmt_ymd_ja           CONSTANT VARCHAR2(20)  := 'YYYY"�N"MM"��"DD"��' ;   -- ����
  gc_max_date_d                CONSTANT VARCHAR2(10)  := '4712/12/31';
  gc_min_date_d                CONSTANT VARCHAR2(10)  := '1900/01/01';
  gc_max_date_dt               CONSTANT VARCHAR2(19)  := '4712/12/31 23:59:59';
  gc_min_date_dt               CONSTANT VARCHAR2(19)  := '1900/01/01 00:00:00';
  -- ���l�t�H�[�}�b�g
  gc_num_5                   CONSTANT  VARCHAR2(10) := '99990.900' ;      -- 5,3
  gc_num_7                   CONSTANT  VARCHAR2(15) := '9999990.90' ;     -- 7,2
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD 
    (
       iv_delivery_dest     VARCHAR2(30)    -- 01:�[����
      ,iv_delivery_form     VARCHAR2(240)   -- 02:�o�Ɍ`��
      ,iv_delivery_date     DATE            -- 03:�[��
      ,iv_delivery_day_from DATE            -- 04:�o�ɓ�From
      ,iv_delivery_day_to   DATE            -- 05:�o�ɓ�To
    ) ;
--
  -- �o�׍w���˗��ꗗ�擾���R�[�h�ϐ�
  TYPE rec_data_type_dtl  IS RECORD 
    (
      -- �[����(�R�[�h)
       location_code          xxpo_requisition_headers.location_code%TYPE
      -- �[����(����)
      ,description            xxcmn_item_locations2_v.description%TYPE
      -- �o�Ɍ`��
      ,transaction_type_name  xxwsh_oe_transaction_types2_v.transaction_type_name%TYPE
      -- ����no
      ,po_header_number       xxpo_requisition_headers.po_header_number%TYPE
      -- �X�e�[�^�X
      ,meaning                xxcmn_lookup_values2_v.meaning%TYPE
      -- �����(�R�[�h)
      ,segment1               xxcmn_vendors2_v.segment1%TYPE
      -- �����(����)
      ,vendor_short_name      xxcmn_vendors2_v.vendor_short_name%TYPE
      -- �[��
      ,promised_date          xxpo_requisition_headers.promised_date%TYPE
      -- �i��(�R�[�h)
      ,item_no                xxcmn_item_mst2_v.item_no%TYPE
      -- �i��(����)
      ,item_desc1             xxcmn_item_mst2_v.item_desc1%TYPE
      -- �����˗�����
      ,requested_quantity     xxpo_requisition_lines.requested_quantity%TYPE
      -- �P��
      ,item_um                xxcmn_item_mst2_v.item_um%TYPE
      -- ���t�w��
      ,requested_date         xxpo_requisition_lines.requested_date%TYPE
      -- �˗�no/�ړ�no
      ,request_move_no             xxwsh_order_headers_all.request_no%TYPE
      -- �o�ɓ�
      ,schedule_ship_date    xxwsh_order_headers_all.schedule_ship_date%TYPE
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  ------------------------------
  -- �w�l�k�p
  ------------------------------
  gd_exec_date              DATE ;               -- ���{��
  gv_department_code        VARCHAR2(10) ;       -- �S������
  gv_department_name        VARCHAR2(14) ;       -- �S����
--
  gt_main_data              tab_data_type_dtl ;  -- �擾���R�[�h�\
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION ;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION ;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  �Œ蕔 END   ############################
--
  /**********************************************************************************
   * Function Name    : convert_into_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION convert_into_xml
    (
      iv_name              IN        VARCHAR2   --   �^�O�l�[��
     ,iv_value             IN        VARCHAR2   --   �^�O�f�[�^
     ,ic_type              IN        CHAR       --   �^�O�^�C�v
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'convert_into_xml' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_convert_data         VARCHAR2(2000) ;
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF (ic_type = gc_tag_type_data) THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END convert_into_xml ;
--
  /**********************************************************************************
   * Procedure Name   : insert_xml_plsql_table
   * Description      : XML�f�[�^�i�[
   ***********************************************************************************/
  PROCEDURE insert_xml_plsql_table(
    iox_xml_data      IN OUT NOCOPY xml_data,
    iv_tag_name       IN     VARCHAR2,
    iv_tag_value      IN     VARCHAR2,
    ic_tag_type       IN     CHAR,
    ic_tag_value_type IN     CHAR)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_xml_plsql_table'; -- �v���O������
--
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
    i NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
    i:= iox_xml_data.COUNT + 1 ;
    iox_xml_data(i).TAG_NAME  := iv_tag_name;
--
    IF (ic_tag_value_type = 'P') THEN
      iox_xml_data(i).TAG_VALUE := TO_CHAR(TO_NUMBER(iv_tag_value),gc_num_5);
    ELSIF (ic_tag_value_type = 'B') THEN
      iox_xml_data(i).TAG_VALUE := TO_CHAR(TO_NUMBER(iv_tag_value),gc_num_7);
    ELSE
      iox_xml_data(i).TAG_VALUE := iv_tag_value;
    END IF;
    iox_xml_data(i).TAG_TYPE  := ic_tag_type;
--
  END insert_xml_plsql_table;
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : �S���ҏ�񒊏o(D-1)
   ***********************************************************************************/
  PROCEDURE prc_initialize
    (
      ir_param      IN     rec_param_data   -- 01.���̓p�����[�^�Q
     ,ov_errbuf     OUT    VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT    VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT    VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_initialize' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    ln_data_cnt     NUMBER := 0 ;   -- �f�[�^�����擾�p
    lv_err_code     VARCHAR2(100) ; -- �G���[�R�[�h�i�[�p
--
    -- *** ���[�J���E��O���� ***
    get_value_expt  EXCEPTION ;     -- �l�擾�G���[
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �S�������擾
    -- ====================================================
    gv_department_code := SUBSTRB( xxcmn_common_pkg.get_user_dept( FND_GLOBAL.USER_ID ), 1, 10 ) ;
--del start 1.1
--    IF ( gv_department_code IS NULL ) THEN
--      lv_err_code := gc_xxpo_00036 ;
--      RAISE get_value_expt ;
--    END IF ;
--del end 1.1
--
    -- ====================================================
    -- �S���Ҏ擾
    -- ====================================================
    gv_department_name := SUBSTRB( xxcmn_common_pkg.get_user_name( FND_GLOBAL.USER_ID ), 1, 14 ) ;
--del start 1.1
--    IF ( gv_department_name IS NULL ) THEN
--      lv_err_code := gc_xxpo_00026 ;
--      RAISE get_value_expt ;
--    END IF ;
--del end 1.1
--
  EXCEPTION
    --*** �l�擾�G���[��O ***
    WHEN get_value_expt THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                            ,lv_err_code    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB( gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg
                             , 1, 5000 ) ;
      ov_retcode := gv_status_error ;
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
  END prc_initialize ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���׃f�[�^�擾(D-2)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data
    (
      ir_param      IN  rec_param_data            -- 01.���̓p�����[�^�Q
     ,ot_data_rec   OUT NOCOPY tab_data_type_dtl  -- 02.�擾���R�[�h�Q
     ,ov_errbuf     OUT VARCHAR2                  --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2                  --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2                  --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_report_data'; -- �v���O������
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
    -- *** ���[�J���E�萔 ***    
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
    -- �f�[�^���o
    -- ====================================================
    SELECT         location_code              AS location_code
                  ,description                AS description
                  ,transaction_type_name      AS transaction_type_name
                  ,po_header_number           AS po_header_number
                  ,meaning                    AS meaning
                  ,segment1                   AS segment1
                  ,vendor_short_name          AS vendor_short_name
                  ,promised_date              AS promised_date
                  ,item_no                    AS item_no
                  ,item_desc1                 AS item_desc1
                  ,requested_quantity         AS requested_quantity
                  ,item_um                    AS item_um
                  ,requested_date             AS requested_date
                  ,request_move_no            AS request_move_no
                  ,schedule_ship_date         AS schedule_ship_date
--
    BULK COLLECT INTO ot_data_rec
--
    FROM
      ------------------------------------------------------------------------
      -- �o�׏��
      ------------------------------------------------------------------------
      (
        SELECT     xrh.location_code            AS location_code            -- �[����(�R�[�h)
                  ,xil2v.description            AS description              -- �[����(����)
                  ,xott2v.transaction_type_name AS transaction_type_name    -- �o�Ɍ`��
                  ,xrh.po_header_number         AS po_header_number         -- ����no
                  ,xlv2v.meaning                AS meaning                  -- �X�e�[�^�X
                  ,xv2v.segment1                AS segment1                 -- �����(�R�[�h)
                  ,xv2v.vendor_short_name       AS vendor_short_name        -- �����(����)
                  ,xrh.promised_date            AS promised_date            -- �[��
                  ,xim2v.item_no                AS item_no                  -- �i��(�R�[�h)
                  ,xim2v.item_desc1             AS item_desc1               -- �i��(����)
                  ,xrl.requested_quantity       AS requested_quantity       -- �����˗�����
                  ,xim2v.item_um                AS item_um                  -- �P��
                  ,xrl.requested_date           AS requested_date           -- ���t�w��
                  ,xoha.request_no              AS request_move_no          -- �˗�no
                  ,xoha.schedule_ship_date      AS schedule_ship_date       -- �o�ɓ�
--
        FROM       xxpo_requisition_headers       xrh     -- �����˗��w�b�_(�A�h�I��)
                  ,xxpo_requisition_lines         xrl     -- �����˗�����(�A�h�I��)
                  ,xxwsh_order_headers_all        xoha    -- �󒍃w�b�_�A�h�I��
                  ,xxwsh_order_lines_all          xola    -- �󒍖��׃A�h�I��
                  ,xxcmn_vendors2_v               xv2v    -- �d������view2
                  ,xxcmn_item_locations2_v        xil2v   -- OPM�ۊǏꏊ���VIEW2
                  ,xxcmn_item_mst2_v              xim2v   -- OPM�i�ڏ��VIEW2
                  ,xxwsh_oe_transaction_types2_v  xott2v  -- �󒍃^�C�v���VIEW2
                  ,xxcmn_lookup_values2_v         xlv2v   -- �N�C�b�N�R�[�h���VIEW2(�`�[�敪)
--
        WHERE
                  -------------------------------------------------------------------------------
                  -- �����˗��w�b�_�A�h�I��
                  -------------------------------------------------------------------------------
                  (
                    xrh.status                 =   gc_order_status_req_making    -- �˗��쐬��
                  OR
                    xrh.status                 =   gc_order_status_ordered       -- ������
                  )
        AND       (
                    ir_param.iv_delivery_dest  IS NULL
                  OR
                    xrh.location_code          =   ir_param.iv_delivery_dest
                  )
        AND       (
                    ir_param.iv_delivery_date  IS NULL
                  OR
                    xrh.promised_date          =   ir_param.iv_delivery_date
                  )
                  -------------------------------------------------------------------------------
                  -- �����˗����׃A�h�I��
                  -------------------------------------------------------------------------------
        AND       xrh.requisition_header_id    =   xrl.requisition_header_id
        AND       xrl.cancelled_flg            <>  gc_cancelled_flg
                  -------------------------------------------------------------------------------
                  -- �󒍖��׃A�h�I��
                  -------------------------------------------------------------------------------
        AND       xrh.po_header_number         =   xola.po_number
        AND       xrl.item_code                =   xola.shipping_item_code
        AND       xola.delete_flag             <>  gc_delete_flag
                  -------------------------------------------------------------------------------
                  -- �󒍃w�b�_�A�h�I��
                  -------------------------------------------------------------------------------
        AND       xola.order_header_id         =   xoha.order_header_id
        AND       xoha.latest_external_flag    =   gc_new_flg
        AND       xoha.req_status              <>  gc_ship_status_delete
        AND       xoha.schedule_ship_date     >=  ir_param.iv_delivery_day_from
        AND       (
                    ir_param.iv_delivery_day_to       IS NULL
                  OR
                    xoha.schedule_ship_date   <= ir_param.iv_delivery_day_to
                  )
                  -------------------------------------------------------------------------------
                  -- �󒍃^�C�v
                  -------------------------------------------------------------------------------
        AND       xoha.order_type_id           =   xott2v.transaction_type_id
        AND       xott2v.shipping_shikyu_class =  gc_ship_pro_kbn_i     -- �o�׈˗�
        AND       xott2v.transaction_type_id
                    = NVL(ir_param.iv_delivery_form, xott2v.transaction_type_id)
                  -------------------------------------------------------------------------------
                  -- OPM�ۊǏꏊ���VIEW
                  -------------------------------------------------------------------------------
        AND       xrh.location_code            =   xil2v.segment1
                  -------------------------------------------------------------------------------
                  -- �d������VIEW
                  -------------------------------------------------------------------------------
        AND       xrh.vendor_id                =  xv2v.vendor_id
        AND       xv2v.start_date_active      <= ir_param.iv_delivery_day_from
        AND       xv2v.end_date_active        >= ir_param.iv_delivery_day_from
                  -------------------------------------------------------------------------------
                  -- OPM�i�ڏ��VIEW
                  -------------------------------------------------------------------------------
        AND       xrl.item_id                  =  xim2v.item_id
        AND       xim2v.start_date_active     <= ir_param.iv_delivery_day_from
        AND       xim2v.end_date_active       >= ir_param.iv_delivery_day_from
                  -------------------------------------------------------------------------------
                  -- �N�C�b�N�R�[�h�i�����˗��X�e�[�^�X�j
                  -------------------------------------------------------------------------------
        AND       xrh.status                   =   xlv2v.lookup_code
        AND       xlv2v.lookup_type            =   gc_lookup_cd_conreq
--
        UNION ALL
--
        ------------------------------------------------------------------------
        -- �ړ����
        ------------------------------------------------------------------------
        SELECT     xrh.location_code            AS location_code            -- �[����(�R�[�h)
                  ,xil2v.description            AS description              -- �[����(����)
                  ,NULL                         AS transaction_type_name    -- �o�Ɍ`��
                  ,xrh.po_header_number         AS po_header_number         -- ����no
                  ,xlv2v.meaning                AS meaning                  -- �X�e�[�^�X
                  ,xv2v.segment1                AS segment1                 -- �����(�R�[�h)
                  ,xv2v.vendor_short_name       AS vendor_short_name        -- �����(����)
                  ,xrh.promised_date            AS promised_date            -- �[��
                  ,xim2v.item_no                AS item_no                  -- �i��(�R�[�h)
                  ,xim2v.item_desc1             AS item_desc1               -- �i��(����)
                  ,xrl.requested_quantity       AS requested_quantity       -- �����˗�����
                  ,xim2v.item_um                AS item_um                  -- �P��
                  ,xrl.requested_date           AS requested_date           -- ���t�w��
                  ,xmrih.mov_num                AS request_move_no          -- �ړ�no
                  ,xmrih.schedule_ship_date     AS schedule_ship_date       -- �o�ɓ�
--
        FROM       xxpo_requisition_headers       xrh     -- �����˗��w�b�_(�A�h�I��)
                  ,xxpo_requisition_lines         xrl     -- �����˗�����(�A�h�I��)
                  ,xxinv_mov_req_instr_headers    xmrih   -- �ړ��˗�/�w���w�b�_(�A�h�I��)
                  ,xxinv_mov_req_instr_lines      xmril   -- �ړ��˗�/�w������(�A�h�I��)
                  ,xxcmn_vendors2_v               xv2v    -- �d������view2
                  ,xxcmn_item_locations2_v        xil2v   -- opm�ۊǏꏊ���view2
                  ,xxcmn_item_mst2_v              xim2v   -- opm�i�ڏ��view2
                  ,xxcmn_lookup_values2_v         xlv2v   -- �N�C�b�N�R�[�h���VIEW2(�`�[�敪)
--
        WHERE
                  -------------------------------------------------------------------------------
                  -- �����˗��w�b�_�A�h�I��
                  -------------------------------------------------------------------------------
                  (
                    xrh.status                 =   gc_order_status_req_making    -- �˗��쐬��
                  OR
                    xrh.status                 =   gc_order_status_ordered       -- ������
                  )
        AND       (
                    ir_param.iv_delivery_dest  IS NULL
                  OR
                    xrh.location_code          =   ir_param.iv_delivery_dest
                  )
        AND       (
                    ir_param.iv_delivery_date  IS NULL
                  OR
                    xrh.promised_date          =   ir_param.iv_delivery_date
                  )
                  -------------------------------------------------------------------------------
                  -- �����˗����׃A�h�I��
                  -------------------------------------------------------------------------------
        AND       xrh.requisition_header_id    =   xrl.requisition_header_id
        AND       xrl.cancelled_flg            <>  gc_cancelled_flg
                  -------------------------------------------------------------------------------
                  -- �ړ��˗�/�w�����׃A�h�I��
                  -------------------------------------------------------------------------------
        AND       xrh.po_header_number         =   xmril.po_num
        AND       xrl.item_code                =   xmril.item_code
        AND       xmril.delete_flg             <>  gc_delete_mov_flag
                  -------------------------------------------------------------------------------
                  -- �ړ��˗�/�w���w�b�_�A�h�I��
                  -------------------------------------------------------------------------------
        AND       xmril.mov_hdr_id             =  xmrih.mov_hdr_id
        AND       xmrih.status                 <>  gc_mov_status_delete
        AND       xmrih.schedule_ship_date    >=  ir_param.iv_delivery_day_from
        AND       (
                    ir_param.iv_delivery_day_to        IS NULL
                  OR
                    xmrih.schedule_ship_date  <=  ir_param.iv_delivery_day_to
                  )
                  -------------------------------------------------------------------------------
                  -- OPM�ۊǏꏊ���VIEW
                  -------------------------------------------------------------------------------
        AND       xrh.location_code            =   xil2v.segment1
                  -------------------------------------------------------------------------------
                  -- �d������VIEW
                  -------------------------------------------------------------------------------
        AND       xrh.vendor_id                =  xv2v.vendor_id
        AND       xv2v.start_date_active      <= ir_param.iv_delivery_day_from
        AND       xv2v.end_date_active        >= ir_param.iv_delivery_day_from
                  -------------------------------------------------------------------------------
                  -- OPM�i�ڏ��VIEW
                  -------------------------------------------------------------------------------
        AND       xrl.item_id                  =  xim2v.item_id
        AND       xim2v.start_date_active     <= ir_param.iv_delivery_day_from
        AND       xim2v.end_date_active       >= ir_param.iv_delivery_day_from
                  -------------------------------------------------------------------------------
                  -- �N�C�b�N�R�[�h�i�����˗��X�e�[�^�X�j
                  -------------------------------------------------------------------------------
        AND       xrh.status                   =   xlv2v.lookup_code
        AND       xlv2v.lookup_type            =   gc_lookup_cd_conreq
      )
      ------------------------------------------------------------------------
      ORDER BY   transaction_type_name          -- �o�Ɍ`��
                ,location_code                  -- �[����(�R�[�h)
                ,promised_date                  -- �[��
                ,po_header_number               -- ����no
                ,item_no                        -- �i��(�R�[�h)
                ,schedule_ship_date             -- �o�ɓ�
                ,request_move_no                -- �˗�no/�ړ�no
                ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf
                          , 1, 5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM||
                    ' A:'||ir_param.iv_delivery_day_to||
                    ' B:'||ir_param.iv_delivery_day_from||
                    ' C:'||ir_param.iv_delivery_day_to;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_report_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�쐬(D-3)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      iox_xml_data      IN OUT  NOCOPY XML_DATA 
     ,ir_param          IN      rec_param_data  -- 01.���R�[�h  �F�p�����[�^
     ,ov_errbuf         OUT     VARCHAR2        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT     VARCHAR2        -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT     VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���萔 ***
    -- ���z�v�Z�p
    ln_collect1_amount           NUMBER := 0 ;           -- �W�ׂP�F���z
    ln_collect2_amount           NUMBER := 0 ;           -- �W�ׂQ�F���z
    ln_receive1_amount           NUMBER := 0 ;           -- ����P�F���z
    ln_receive2_amount           NUMBER := 0 ;           -- ����Q�F���z
    ln_shipment_amount           NUMBER := 0 ;           -- �o�ׁF���z
    ln_total_quantity            NUMBER := 0 ;           -- ���t���v�F����
    ln_total_amount              NUMBER := 0 ;           -- ���t���v�F���z
    ln_byproduct1_amount         NUMBER := 0 ;           -- ���Y���P�F���z
    ln_byproduct2_amount         NUMBER := 0 ;           -- ���Y���Q�F���z
    ln_byproduct3_amount         NUMBER := 0 ;           -- ���Y���R�F���z
    ln_byproduct_total_quantity  NUMBER := 0 ;           -- ���Y�����v�F����
    ln_byproduct_total_amount    NUMBER := 0 ;           -- ���Y�����v�F���z
    ln_aracha_unit_price         NUMBER := 0 ;           -- �r���������v�F�P��
    ln_aracha_amount             NUMBER := 0 ;           -- �r���������v�F���z
    ln_budomari                  NUMBER := 0 ;           -- ����
    ln_amount                    NUMBER := 0 ;           -- �Г��U�ցi�r���j�F���z
    ln_receive_total_quantity    NUMBER := 0 ;           -- ������v�F����
    ln_receive_total_amount      NUMBER := 0 ;           -- ������v�F���z
--
    -- ���ɑq�Ɏ擾�p
    lv_location_name        xxcmn_item_locations2_v.description%TYPE ; -- ���ɑq��
--
    -- �[����(����)
    lv_location_code          xxpo_requisition_headers.location_code%TYPE;
    -- �o�Ɍ`��
    lv_transaction_type_name  xxwsh_oe_transaction_types2_v.transaction_type_name%TYPE;
    -- ����no
    lv_po_header_number       xxpo_requisition_headers.po_header_number%TYPE;
    -- �X�e�[�^�X
    lv_meaning                xxcmn_lookup_values2_v.meaning%TYPE;
    -- �����(����)
    lv_segment1               xxcmn_vendors2_v.segment1%TYPE;
    -- �����(����)
    lv_vendor_short_name      xxcmn_vendors2_v.vendor_short_name%TYPE;
    -- �[��
    lv_promised_date          xxpo_requisition_headers.promised_date%TYPE;
    -- �i��(����)
    lv_item_no                xxcmn_item_mst2_v.item_no%TYPE;
--
    -- *** ���[�J���E��O���� ***
    no_data_expt                 EXCEPTION ;             -- �擾���R�[�h�Ȃ�
--
  BEGIN
--
    -- =====================================================
    -- ���׏��擾(D-2)
    -- =====================================================
    prc_get_report_data
      (
        ir_param      => ir_param       -- 01.���̓p�����[�^�Q
       ,ot_data_rec   => gt_main_data   -- 02.�擾���R�[�h�Q
       ,ov_errbuf     => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt ;
--
    -- �擾�f�[�^���O���̏ꍇ
    ELSIF ( gt_main_data.COUNT = 0 ) THEN
      RAISE no_data_expt ;
--
    END IF ;
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
--
    -- �u���C�N�L�[�̏�����
    lv_location_code          :=  NULL;
    lv_transaction_type_name  :=  NULL;
    lv_po_header_number       :=  NULL;
    lv_meaning                :=  NULL;
    lv_segment1               :=  NULL;
    lv_vendor_short_name      :=  NULL;
    lv_promised_date          :=  NULL;
    lv_item_no                :=  NULL;
--
    -- -----------------------------------------------------
    -- �f�[�^�f�J�n�^�O�o��
    -- -----------------------------------------------------
    insert_xml_plsql_table( iox_xml_data
                           ,'root'
                           ,NULL
                           ,gc_tag_type_tag
                           ,gc_tag_value_type_char);
    insert_xml_plsql_table( iox_xml_data
                           ,'data_info'
                           ,NULL
                           ,gc_tag_type_tag
                           ,gc_tag_value_type_char);
    -- -----------------------------------------------------
    -- �`�[�f�J�n�^�O�o��
    -- -----------------------------------------------------
    insert_xml_plsql_table( iox_xml_data
                           ,'lg_denpyo_info'
                           ,NULL
                           ,gc_tag_type_tag
                           ,gc_tag_value_type_char);
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
--
      -- �u���C�N�L�[�̃`�F�b�N
      IF  ( lv_location_code          IS NULL ) 
      AND ( lv_transaction_type_name  IS NULL ) 
      AND ( lv_po_header_number       IS NULL ) 
      AND ( lv_meaning                IS NULL ) 
      AND ( lv_segment1               IS NULL ) 
      AND ( lv_vendor_short_name      IS NULL ) 
      AND ( lv_promised_date          IS NULL ) 
      AND ( lv_item_no                IS NULL ) THEN
--
        -- �ϐ����X�V����B
        lv_location_code          :=  gt_main_data(i).location_code;
        lv_transaction_type_name  :=  gt_main_data(i).transaction_type_name;
        lv_po_header_number       :=  gt_main_data(i).po_header_number;
        lv_meaning                :=  gt_main_data(i).meaning;
        lv_segment1               :=  gt_main_data(i).segment1;
        lv_vendor_short_name      :=  gt_main_data(i).vendor_short_name;
        lv_promised_date          :=  gt_main_data(i).promised_date;
        lv_item_no                :=  gt_main_data(i).item_no;
--
        -- ����o�͂͑S�Ẵ^�O���o�͂���B
        -- -----------------------------------------------------
        -- ���ׂf�J�n�^�O�o��
        -- -----------------------------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_denpyo'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char);
--
        -- -----------------------------------------------------
        -- ���ׂf�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- ���[ID
        insert_xml_plsql_table( iox_xml_data
                               ,'tyohyo_id'
                               ,gc_report_id
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �o�͓��t
        insert_xml_plsql_table( iox_xml_data
                               ,'shuturyoku_hiduke'
                               ,TO_CHAR(gd_exec_date, gc_char_dt_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �S���i�����j
        insert_xml_plsql_table( iox_xml_data
                               ,'tantou_busho'
                               ,gv_department_code
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �S���i�����j
        insert_xml_plsql_table( iox_xml_data
                               ,'tantou_name'
                               ,gv_department_name
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �o�ɓ�From
        insert_xml_plsql_table( iox_xml_data
                               ,'syukkobi_from'
                               ,TO_CHAR(ir_param.iv_delivery_day_from, gc_date_fmt_ymd_ja)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �o�ɓ�To
        insert_xml_plsql_table( iox_xml_data
                               ,'syukkobi_to'
                               ,TO_CHAR(ir_param.iv_delivery_day_to, gc_date_fmt_ymd_ja)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char);
        -- �[����(�R�[�h)
        insert_xml_plsql_table( iox_xml_data
                               ,'nounyu_saki_code'
                               ,gt_main_data(i).location_code
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �[����(����)
        insert_xml_plsql_table( iox_xml_data
                               ,'nounyu_saki_name'
                               ,gt_main_data(i).description
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �o�Ɍ`��
        insert_xml_plsql_table( iox_xml_data
                               ,'syukko_keitai'
                               ,gt_main_data(i).transaction_type_name
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- ���ׂk�f�J�n�^�O
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'lg_shukko'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- ����(�e)�f�J�n�^�O
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_shukko_header'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        -- -----------------------------------------------------
        -- ����(�e)�f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- ����no
        insert_xml_plsql_table( iox_xml_data
                               ,'hattyu_no'
                               ,gt_main_data(i).po_header_number
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �X�e�[�^�X
        insert_xml_plsql_table( iox_xml_data
                               ,'status'
                               ,gt_main_data(i).meaning
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �����(�R�[�h)
        insert_xml_plsql_table( iox_xml_data
                               ,'torihikisaki_code'
                               ,gt_main_data(i).segment1
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �����(����)
        insert_xml_plsql_table( iox_xml_data
                               ,'torihikisaki_name'
                               ,gt_main_data(i).vendor_short_name
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �[��
        insert_xml_plsql_table( iox_xml_data
                               ,'nouki'
                               ,TO_CHAR(gt_main_data(i).promised_date, gc_char_d_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- ����(�q)�f�J�n�^�O
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_shukko_detail'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        -- �i��(�R�[�h)
        insert_xml_plsql_table( iox_xml_data
                               ,'hinmoku_code'
                               ,gt_main_data(i).item_no
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �i��(����)
        insert_xml_plsql_table( iox_xml_data
                               ,'hinmoku_name'
                               ,gt_main_data(i).item_desc1
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �����˗�����
        insert_xml_plsql_table( iox_xml_data
                               ,'hattyuuirai_suryo'
                               ,gt_main_data(i).requested_quantity
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �P��
        insert_xml_plsql_table( iox_xml_data
                               ,'unit'
                               ,gt_main_data(i).item_um
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- ���t�w��
        insert_xml_plsql_table( iox_xml_data
                               ,'hiduke_shitei'
                               ,TO_CHAR(gt_main_data(i).requested_date, gc_char_d_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- ����(��)�f�J�n�^�O
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_shukko_detail2'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        -- �˗�NO/�ړ�NO
        insert_xml_plsql_table( iox_xml_data
                               ,'irai_idou_no'
                               ,gt_main_data(i).request_move_no
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �o�ɓ�
        insert_xml_plsql_table( iox_xml_data
                               ,'syukkobi'
                               ,TO_CHAR(gt_main_data(i).schedule_ship_date, gc_char_d_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- ����(��)�f�I���^�O
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'/g_shukko_detail2'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
      -- �w�b�_�[���̉��y�[�W�������ύX�ɂȂ�������y�[�W���s���B
      ELSIF ( lv_location_code          <>  gt_main_data(i).location_code         )
-- mod start ver1.3
--        OR  ( lv_transaction_type_name  <>  gt_main_data(i).transaction_type_name ) THEN
        OR  ( lv_transaction_type_name  <>  gt_main_data(i).transaction_type_name )
        OR  ( lv_transaction_type_name IS NULL  AND  gt_main_data(i).transaction_type_name IS NOT NULL)
        OR  ( lv_transaction_type_name IS NOT NULL  AND  gt_main_data(i).transaction_type_name IS NULL) THEN
-- mod end ver1.3
--
        -- �ϐ����X�V����B
        lv_location_code          :=  gt_main_data(i).location_code;
        lv_transaction_type_name  :=  gt_main_data(i).transaction_type_name;
        lv_po_header_number       :=  gt_main_data(i).po_header_number;
        lv_meaning                :=  gt_main_data(i).meaning;
        lv_segment1               :=  gt_main_data(i).segment1;
        lv_vendor_short_name      :=  gt_main_data(i).vendor_short_name;
        lv_promised_date          :=  gt_main_data(i).promised_date;
        lv_item_no                :=  gt_main_data(i).item_no;
--
        ------------------------------
        -- ����(�q)�f�I���^�O
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'/g_shukko_detail'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
--
        ------------------------------
        -- ����(�e)�f�I���^�O
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'/g_shukko_header'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
--
        ------------------------------
        -- ���ׂk�f�I���^�O
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'/lg_shukko'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
--
        -- -----------------------------------------------------
        -- ���ׂf�I���^�O�o��
        -- -----------------------------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'/g_denpyo'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
--
        -- -----------------------------------------------------
        -- ���ׂf�J�n�^�O�o��
        -- -----------------------------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_denpyo'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char);
--
        -- -----------------------------------------------------
        -- ���ׂf�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- ���[ID
        insert_xml_plsql_table( iox_xml_data
                               ,'tyohyo_id'
                               ,gc_report_id
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �o�͓��t
        insert_xml_plsql_table( iox_xml_data
                               ,'shuturyoku_hiduke'
                               ,TO_CHAR(gd_exec_date, gc_char_dt_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �S���i�����j
        insert_xml_plsql_table( iox_xml_data
                               ,'tantou_busho'
                               ,gv_department_code
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �S���i�����j
        insert_xml_plsql_table( iox_xml_data
                               ,'tantou_name'
                               ,gv_department_name
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �o�ɓ�From
        insert_xml_plsql_table( iox_xml_data
                               ,'syukkobi_from'
                               ,TO_CHAR(ir_param.iv_delivery_day_from, gc_date_fmt_ymd_ja)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �o�ɓ�To
        insert_xml_plsql_table( iox_xml_data
                               ,'syukkobi_to'
                               ,TO_CHAR(ir_param.iv_delivery_day_to, gc_date_fmt_ymd_ja)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char);
        -- �[����(�R�[�h)
        insert_xml_plsql_table( iox_xml_data
                               ,'nounyu_saki_code'
                               ,gt_main_data(i).location_code
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �[����(����)
        insert_xml_plsql_table( iox_xml_data
                               ,'nounyu_saki_name'
                               ,gt_main_data(i).description
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �o�Ɍ`��
        insert_xml_plsql_table( iox_xml_data
                               ,'syukko_keitai'
                               ,gt_main_data(i).transaction_type_name
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- ���ׂk�f�J�n�^�O
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'lg_shukko'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- ����(�e)�f�J�n�^�O
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_shukko_header'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        -- -----------------------------------------------------
        -- ����(�e)�f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- ����no
        insert_xml_plsql_table( iox_xml_data
                               ,'hattyu_no'
                               ,gt_main_data(i).po_header_number
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �X�e�[�^�X
        insert_xml_plsql_table( iox_xml_data
                               ,'status'
                               ,gt_main_data(i).meaning
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �����(�R�[�h)
        insert_xml_plsql_table( iox_xml_data
                               ,'torihikisaki_code'
                               ,gt_main_data(i).segment1
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �����(����)
        insert_xml_plsql_table( iox_xml_data
                               ,'torihikisaki_name'
                               ,gt_main_data(i).vendor_short_name
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �[��
        insert_xml_plsql_table( iox_xml_data
                               ,'nouki'
                               ,TO_CHAR(gt_main_data(i).promised_date, gc_char_d_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- ����(�q)�f�J�n�^�O
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_shukko_detail'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        -- �i��(�R�[�h)
        insert_xml_plsql_table( iox_xml_data
                               ,'hinmoku_code'
                               ,gt_main_data(i).item_no
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �i��(����)
        insert_xml_plsql_table( iox_xml_data
                               ,'hinmoku_name'
                               ,gt_main_data(i).item_desc1
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �����˗�����
        insert_xml_plsql_table( iox_xml_data
                               ,'hattyuuirai_suryo'
                               ,gt_main_data(i).requested_quantity
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �P��
        insert_xml_plsql_table( iox_xml_data
                               ,'unit'
                               ,gt_main_data(i).item_um
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- ���t�w��
        insert_xml_plsql_table( iox_xml_data
                               ,'hiduke_shitei'
                               ,TO_CHAR(gt_main_data(i).requested_date, gc_char_d_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- ����(��)�f�J�n�^�O
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_shukko_detail2'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        -- �˗�NO/�ړ�NO
        insert_xml_plsql_table( iox_xml_data
                               ,'irai_idou_no'
                               ,gt_main_data(i).request_move_no
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �o�ɓ�(�˗�no)
        insert_xml_plsql_table( iox_xml_data
                               ,'syukkobi'
                               ,TO_CHAR(gt_main_data(i).schedule_ship_date, gc_char_d_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- ����(��)�f�I���^�O
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'/g_shukko_detail2'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
      -- �e�̃u���C�N�L�[�����ꂩ���ύX�ɂȂ����ꍇ�A�e�Ǝq�Ƒ����o�͂���B
      ELSIF ( lv_location_code          =   gt_main_data(i).location_code         )
-- mod start ver1.3
--        AND ( lv_transaction_type_name  =   gt_main_data(i).transaction_type_name )
        AND (( lv_transaction_type_name  =   gt_main_data(i).transaction_type_name )
          OR (lv_transaction_type_name IS NULL AND gt_main_data(i).transaction_type_name IS NULL))
-- mod end ver1.3
        AND ( lv_po_header_number       <>  gt_main_data(i).po_header_number      )
        OR  ( lv_meaning                <>  gt_main_data(i).meaning               )
        OR  ( lv_segment1               <>  gt_main_data(i).segment1              )
        OR  ( lv_vendor_short_name      <>  gt_main_data(i).vendor_short_name     )
        OR  ( lv_promised_date          <>  gt_main_data(i).promised_date         ) THEN
--
        -- �ϐ����X�V����B
        lv_po_header_number     :=  gt_main_data(i).po_header_number;
        lv_meaning              :=  gt_main_data(i).meaning;
        lv_segment1             :=  gt_main_data(i).segment1;
        lv_vendor_short_name    :=  gt_main_data(i).vendor_short_name;
        lv_promised_date        :=  gt_main_data(i).promised_date;
        lv_item_no              :=  gt_main_data(i).item_no;
--
        ------------------------------
        -- ����(�q)�f�I���^�O
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'/g_shukko_detail'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
--
        ------------------------------
        -- ����(�e)�f�I���^�O
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'/g_shukko_header'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
--
        ------------------------------
        -- ����(�e)�f�J�n�^�O
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_shukko_header'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        -- -----------------------------------------------------
        -- ����(�e)�f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- ����no
        insert_xml_plsql_table( iox_xml_data
                               ,'hattyu_no'
                               ,gt_main_data(i).po_header_number
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �X�e�[�^�X
        insert_xml_plsql_table( iox_xml_data
                               ,'status'
                               ,gt_main_data(i).meaning
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �����(�R�[�h)
        insert_xml_plsql_table( iox_xml_data
                               ,'torihikisaki_code'
                               ,gt_main_data(i).segment1
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �����(����)
        insert_xml_plsql_table( iox_xml_data
                               ,'torihikisaki_name'
                               ,gt_main_data(i).vendor_short_name
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �[��
        insert_xml_plsql_table( iox_xml_data
                               ,'nouki'
                               ,TO_CHAR(gt_main_data(i).promised_date, gc_char_d_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- ����(�q)�f�J�n�^�O
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_shukko_detail'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        -- �i��(�R�[�h)
        insert_xml_plsql_table( iox_xml_data
                               ,'hinmoku_code'
                               ,gt_main_data(i).item_no
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �i��(����)
        insert_xml_plsql_table( iox_xml_data
                               ,'hinmoku_name'
                               ,gt_main_data(i).item_desc1
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �����˗�����
        insert_xml_plsql_table( iox_xml_data
                               ,'hattyuuirai_suryo'
                               ,gt_main_data(i).requested_quantity
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �P��
        insert_xml_plsql_table( iox_xml_data
                               ,'unit'
                               ,gt_main_data(i).item_um
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- ���t�w��
        insert_xml_plsql_table( iox_xml_data
                               ,'hiduke_shitei'
                               ,TO_CHAR(gt_main_data(i).requested_date, gc_char_d_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- ����(��)�f�J�n�^�O
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_shukko_detail2'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        -- �˗�NO/�ړ�NO
        insert_xml_plsql_table( iox_xml_data
                               ,'irai_idou_no'
                               ,gt_main_data(i).request_move_no
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �o�ɓ�(�˗�no)
        insert_xml_plsql_table( iox_xml_data
                               ,'syukkobi'
                               ,TO_CHAR(gt_main_data(i).schedule_ship_date, gc_char_d_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- ����(��)�f�I���^�O
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'/g_shukko_detail2'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
      -- �q�̃u���C�N�L�[���ύX�ɂȂ����ꍇ�A�q�Ƒ����o�͂���B
      ELSIF ( lv_location_code          =   gt_main_data(i).location_code         )
-- mod start ver1.3
--        AND ( lv_transaction_type_name  =   gt_main_data(i).transaction_type_name )
        AND (( lv_transaction_type_name  =   gt_main_data(i).transaction_type_name )
          OR (lv_transaction_type_name IS NULL AND gt_main_data(i).transaction_type_name IS NULL))
-- mod end ver1.3
        AND ( lv_po_header_number       =   gt_main_data(i).po_header_number      )
        AND ( lv_meaning                =   gt_main_data(i).meaning               )
        AND ( lv_segment1               =   gt_main_data(i).segment1              )
        AND ( lv_vendor_short_name      =   gt_main_data(i).vendor_short_name     )
        AND ( lv_promised_date          =   gt_main_data(i).promised_date         )
        AND ( lv_item_no                <>  gt_main_data(i).item_no               ) THEN
--
        -- �ϐ����X�V����B
        lv_item_no              :=  gt_main_data(i).item_no;
--
        ------------------------------
        -- ����(�q)�f�I���^�O
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'/g_shukko_detail'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
--
        ------------------------------
        -- ����(�q)�f�J�n�^�O
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_shukko_detail'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        -- �i��(�R�[�h)
        insert_xml_plsql_table( iox_xml_data
                               ,'hinmoku_code'
                               ,gt_main_data(i).item_no
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �i��(����)
        insert_xml_plsql_table( iox_xml_data
                               ,'hinmoku_name'
                               ,gt_main_data(i).item_desc1
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �����˗�����
        insert_xml_plsql_table( iox_xml_data
                               ,'hattyuuirai_suryo'
                               ,gt_main_data(i).requested_quantity
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �P��
        insert_xml_plsql_table( iox_xml_data
                               ,'unit'
                               ,gt_main_data(i).item_um
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- ���t�w��
        insert_xml_plsql_table( iox_xml_data
                               ,'hiduke_shitei'
                               ,TO_CHAR(gt_main_data(i).requested_date, gc_char_d_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- ����(��)�f�J�n�^�O
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_shukko_detail2'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        -- �˗�NO/�ړ�NO
        insert_xml_plsql_table( iox_xml_data
                               ,'irai_idou_no'
                               ,gt_main_data(i).request_move_no
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �o�ɓ�(�˗�no)
        insert_xml_plsql_table( iox_xml_data
                               ,'syukkobi'
                               ,TO_CHAR(gt_main_data(i).schedule_ship_date, gc_char_d_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- ����(��)�f�I���^�O
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'/g_shukko_detail2'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
      -- �����u���C�N�L�[�ɕύX�����������ꍇ�A�����o�͂���B
      ELSIF ( lv_location_code          =   gt_main_data(i).location_code         )
-- mod start ver1.3
--        AND ( lv_transaction_type_name  =   gt_main_data(i).transaction_type_name )
        AND (( lv_transaction_type_name  =   gt_main_data(i).transaction_type_name )
          OR (lv_transaction_type_name IS NULL AND gt_main_data(i).transaction_type_name IS NULL))
-- mod end ver1.3
        AND ( lv_po_header_number       =   gt_main_data(i).po_header_number      )
        AND ( lv_meaning                =   gt_main_data(i).meaning               )
        AND ( lv_segment1               =   gt_main_data(i).segment1              )
        AND ( lv_vendor_short_name      =   gt_main_data(i).vendor_short_name     )
        AND ( lv_promised_date          =   gt_main_data(i).promised_date         )
        AND ( lv_item_no                =   gt_main_data(i).item_no               ) THEN
--
        ------------------------------
        -- ����(��)�f�J�n�^�O
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'g_shukko_detail2'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
        -- �˗�NO/�ړ�NO
        insert_xml_plsql_table( iox_xml_data
                               ,'irai_idou_no'
                               ,gt_main_data(i).request_move_no
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
        -- �o�ɓ�(�˗�no)
        insert_xml_plsql_table( iox_xml_data
                               ,'syukkobi'
                               ,TO_CHAR(gt_main_data(i).schedule_ship_date, gc_char_d_format)
                               ,gc_tag_type_data
                               ,gc_tag_value_type_char) ;
--
        ------------------------------
        -- ����(��)�f�I���^�O
        ------------------------------
        insert_xml_plsql_table( iox_xml_data
                               ,'/g_shukko_detail2'
                               ,NULL
                               ,gc_tag_type_tag
                               ,gc_tag_value_type_char) ;
--
--
      END IF ;
--
    END LOOP main_data_loop ;
--
    ------------------------------
    -- ����(�q)�f�I���^�O
    ------------------------------
    insert_xml_plsql_table( iox_xml_data
                           ,'/g_shukko_detail'
                           ,NULL
                           ,gc_tag_type_tag
                           ,gc_tag_value_type_char) ;
--
--
    ------------------------------
    -- ����(�e)�f�I���^�O
    ------------------------------
    insert_xml_plsql_table( iox_xml_data
                           ,'/g_shukko_header'
                           ,NULL
                           ,gc_tag_type_tag
                           ,gc_tag_value_type_char) ;
--
--
    ------------------------------
    -- ���ׂk�f�I���^�O
    ------------------------------
    insert_xml_plsql_table( iox_xml_data
                           ,'/lg_shukko'
                           ,NULL
                           ,gc_tag_type_tag
                           ,gc_tag_value_type_char) ;
--
--
    -- -----------------------------------------------------
    -- ���ׂf�I���^�O�o��
    -- -----------------------------------------------------
    insert_xml_plsql_table( iox_xml_data
                           ,'/g_denpyo'
                           ,NULL
                           ,gc_tag_type_tag
                           ,gc_tag_value_type_char) ;
--
    -- =====================================================
    -- �I������
    -- =====================================================
    ------------------------------
    -- �`�[�f�I���^�O
    ------------------------------
    insert_xml_plsql_table( iox_xml_data
                           ,'/lg_denpyo_info'
                           ,NULL
                           ,gc_tag_type_tag
                           ,gc_tag_value_type_char) ;
    ------------------------------
    -- �f�[�^�f�I���^�O
    ------------------------------
    insert_xml_plsql_table( iox_xml_data
                           ,'/data_info'
                           ,NULL
                           ,gc_tag_type_tag
                           ,gc_tag_value_type_char) ;
    insert_xml_plsql_table( iox_xml_data
                           ,'/root'
                           ,NULL
                           ,gc_tag_type_tag
                           ,gc_tag_value_type_char) ;
--
  EXCEPTION
    -- *** �擾�f�[�^�O�� ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application_cmn
                                             ,gc_xxcmn_10122 ) ;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
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
  END prc_create_xml_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_check_param_data
   * Description      : �p�����[�^�`�F�b�N����
   ***********************************************************************************/
  PROCEDURE prc_check_param_data
    (
       iv_delivery_date       IN  VARCHAR2      -- 03 : �[��
      ,iv_delivery_day_from   IN  VARCHAR2      -- 04 : �o�ɓ�From
      ,iv_delivery_day_to     IN  VARCHAR2      -- 05 : �o�ɓ�To
      ,ov_delivery_date       OUT DATE          -- 03 : �[��
      ,ov_delivery_day_from   OUT DATE          -- 04 : �o�ɓ�From
      ,ov_delivery_day_to     OUT DATE          -- 05 : �o�ɓ�To
      ,ov_errbuf              OUT VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode             OUT VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg              OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name           CONSTANT  VARCHAR2(100) := 'prc_check_param_data'; -- �v���O������
--
    gc_application_cmn    CONSTANT  VARCHAR2(5)   := 'XXCMN' ;      -- �A�v���P�[�V�����iXXCMN�j
    gc_application_wip    CONSTANT  VARCHAR2(5)   := 'XXWIP' ;      -- �A�v���P�[�V�����iXXWIP�j
    gv_tkn_item           CONSTANT  VARCHAR2(100) := 'ITEM';        -- �g�[�N���FITEM
    gv_tkn_value          CONSTANT  VARCHAR2(100) := 'VALUE';       -- �g�[�N���FVALUE
    gv_delivery_day_from  CONSTANT  VARCHAR2(20)  := '�o�ɓ�From';  -- ���Y�\����iFROM�j
    gv_delivery_day_to    CONSTANT  VARCHAR2(20)  := '�o�ɓ�To';    -- ���Y�\����iTO�j
    gv_tkn_param1         CONSTANT  VARCHAR2(100) := 'PARAM1';      -- �g�[�N���FPARAM1
    gv_tkn_param2         CONSTANT  VARCHAR2(100) := 'PARAM2';      -- �g�[�N���FPARAM2
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
    -- ���ʊ֐��߂�l�F���l�^
    ln_ret_num              NUMBER ;
--
    -- *** ���[�J���E��O���� ***
    parameter_check_expt      EXCEPTION ;     -- �p�����[�^�`�F�b�N��O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���t�ϊ�
    IF ( iv_delivery_date IS NOT NULL ) THEN
      ov_delivery_date := FND_DATE.STRING_TO_DATE(SUBSTR(iv_delivery_date, 1, 10)
                                                , gc_char_d_format);
    END IF;
--
    IF ( iv_delivery_day_from IS NOT NULL ) THEN
      ov_delivery_day_from := FND_DATE.STRING_TO_DATE(SUBSTR(iv_delivery_day_from, 1, 10)
                                                    , gc_char_d_format);
    END IF;
--
    IF ( iv_delivery_day_to IS NOT NULL ) THEN
      ov_delivery_day_to := FND_DATE.STRING_TO_DATE(SUBSTR(iv_delivery_day_to, 1, 10)
                                                  , gc_char_d_format);
    END IF;
--
    -- ====================================================
    -- �Ó����`�F�b�N
    -- ====================================================
    IF ( iv_delivery_day_to IS NOT NULL ) THEN
      IF (ov_delivery_day_from > ov_delivery_day_to) THEN
        -- ���b�Z�[�W�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wip
                                              ,gc_xxwip_10016
                                              ,gv_tkn_param1
                                              ,TO_CHAR(ov_delivery_day_from, gc_char_d_format)
                                              ,gv_tkn_param2
                                              ,TO_CHAR(ov_delivery_day_to, gc_char_d_format)) ;
        RAISE parameter_check_expt ;
      END IF;
    END IF;
--
  EXCEPTION
    --*** �p�����[�^�`�F�b�N��O ***
    WHEN parameter_check_expt THEN
--
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
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
  END prc_check_param_data ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain
    (
       iv_delivery_dest     IN    VARCHAR2          -- 01 : �[����
      ,iv_delivery_form     IN    VARCHAR2          -- 02 : �o�Ɍ`��
      ,iv_delivery_date     IN    VARCHAR2          -- 03 : �[��
      ,iv_delivery_day_from IN    VARCHAR2          -- 04 : �o�ɓ�From
      ,iv_delivery_day_to   IN    VARCHAR2          -- 05 : �o�ɓ�To
      ,ov_errbuf            OUT   VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode           OUT   VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg            OUT   VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name CONSTANT  VARCHAR2(100) := 'submain' ;  -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf   VARCHAR2(5000) ;                        -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1) ;                           -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000) ;                        -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- ���t�ϊ�
    lv_delivery_date      VARCHAR2(10);                 -- �[��
    lv_delivery_day_from  VARCHAR2(10);                 -- �o�ɓ�From
    lv_delivery_day_to    VARCHAR2(10);                 -- �o�ɓ�To
--
--###########################  �Œ蕔 END   ####################################
--
    -- ======================================================
    -- ���[�U�[�錾��
    -- ======================================================
    -- *** ���[�J���ϐ� ***
    lr_param_rec          rec_param_data ;          -- �p�����[�^��n���p
--
    xml_data_table        XML_DATA;
    lv_xml_string         VARCHAR2(32000) ;
    ln_retcode            NUMBER ;
    lv_delivery_dest_name xxcmn_item_locations2_v.description%TYPE ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- ��������
    -- =====================================================
    -- ���[�o�͒l�i�[
    gd_exec_date                      :=  SYSDATE ;  -- ���{��
    -- =====================================================
    -- �p�����[�^�`�F�b�N
    -- =====================================================
    prc_check_param_data
      (
        iv_delivery_date      =>  iv_delivery_date      -- �[��
       ,iv_delivery_day_from  =>  iv_delivery_day_from  -- �o�ɓ�From
       ,iv_delivery_day_to    =>  iv_delivery_day_to    -- �o�ɓ�To
       ,ov_delivery_date      =>  lv_delivery_date      -- �[��
       ,ov_delivery_day_from  =>  lv_delivery_day_from  -- �o�ɓ�From
       ,ov_delivery_day_to    =>  lv_delivery_day_to    -- �o�ɓ�To
       ,ov_errbuf             =>  lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode            =>  lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg             =>  lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- �p�����[�^�i�[
    lr_param_rec.iv_delivery_dest     :=  iv_delivery_dest ;                -- 01 : �[����
    lr_param_rec.iv_delivery_form     :=  iv_delivery_form ;                -- 02 : �o�Ɍ`��
    lr_param_rec.iv_delivery_date     :=  lv_delivery_date ;                -- 03 : �[��
    lr_param_rec.iv_delivery_day_from :=  lv_delivery_day_from ;            -- 04 : �o�ɓ�From
    lr_param_rec.iv_delivery_day_to   :=  lv_delivery_day_to ;              -- 05 : �o�ɓ�To
--
    -- =====================================================
    -- �O����(D-1)
    -- =====================================================
    prc_initialize
      (
        ir_param          => lr_param_rec       -- ���̓p�����[�^�Q
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- �f�[�^�o��(D-3)
    -- =====================================================
    prc_create_xml_data
      (
        xml_data_table
       ,ir_param          => lr_param_rec       -- ���̓p�����[�^���R�[�h
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- �w�l�k�o��(D-3)
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF  ( lv_errmsg IS NOT NULL )
    AND ( lv_retcode = gv_status_warn ) THEN
--
      -- �o�Ɍ`�Ԃ̎���^�C�v���擾����B
      BEGIN
        SELECT  xott2v.transaction_type_name   AS transaction_type_name  -- �o�Ɍ`��
        INTO    lr_param_rec.iv_delivery_form
        FROM    xxwsh_oe_transaction_types2_v  xott2v                     -- �󒍃^�C�v���view2
        WHERE   xott2v.transaction_type_id = iv_delivery_form;
      EXCEPTION
        WHEN  OTHERS  THEN
          NULL;
      END;
--
      -- �[���於�̂��擾����B
      BEGIN
        SELECT  xil2v.description           AS description    -- �[����(����)
        INTO    lv_delivery_dest_name
        FROM    xxcmn_item_locations2_v     xil2v             -- opm�ۊǏꏊ���view2
        WHERE   xil2v.segment1          =   lr_param_rec.iv_delivery_dest;
      EXCEPTION
        WHEN  OTHERS  THEN
          NULL;
      END;
--
      -- �O�����b�Z�[�W�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_denpyo_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_denpyo>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <tyohyo_id>' 
        || gc_report_id 
        || '</tyohyo_id>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <shuturyoku_hiduke>' 
        || TO_CHAR(gd_exec_date, gc_char_dt_format) 
        || '</shuturyoku_hiduke>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <tantou_busho>' 
        || gv_department_code 
        || '</tantou_busho>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <tantou_name>' 
        || gv_department_name 
        || '</tantou_name>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <syukkobi_from>' 
        || TO_CHAR(lr_param_rec.iv_delivery_day_from, gc_date_fmt_ymd_ja) 
        || '</syukkobi_from>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <syukkobi_to>' 
        || TO_CHAR(lr_param_rec.iv_delivery_day_to, gc_date_fmt_ymd_ja) 
        || '</syukkobi_to>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <nounyu_saki_code>' 
        || lr_param_rec.iv_delivery_dest 
        || '</nounyu_saki_code>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <nounyu_saki_name>' 
        || lv_delivery_dest_name 
        || '</nounyu_saki_name>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <syukko_keitai>' 
        || lr_param_rec.iv_delivery_form 
        || '</syukko_keitai>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_shukko>' ) ;
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <msg>' 
        || lv_errmsg 
      || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_shukko>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_denpyo>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_denpyo_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    -- --------------------------------------------------
    -- ���[�f�[�^���o�͂ł����ꍇ
    -- --------------------------------------------------
    ELSE
      --XML�f�[�^���o��
      <<xml_loop>>
      FOR i IN 1 .. xml_data_table.COUNT LOOP
        -- �ҏW�����f�[�^���^�O�ɕϊ�
        lv_xml_string := convert_into_xml
                          (
                            iv_name   => xml_data_table(i).tag_name    -- �^�O�l�[��
                           ,iv_value  => xml_data_table(i).tag_value   -- �^�O�f�[�^
                           ,ic_type   => xml_data_table(i).tag_type    -- �^�O�^�C�v
                          ) ;
        -- �w�l�k�^�O�o��
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
      END LOOP xml_loop ;
--
    END IF ;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errbuf ;
      ov_retcode := gv_status_error ;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
--
--####################################  �Œ蕔 END   ##########################################
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main
    (
       errbuf                 OUT   VARCHAR2          -- �G���[���b�Z�[�W
      ,retcode                OUT   VARCHAR2          -- �G���[�R�[�h
      ,iv_delivery_dest       IN    VARCHAR2          -- 01 : �[����
      ,iv_delivery_form       IN    VARCHAR2          -- 02 : �o�Ɍ`��
      ,iv_delivery_date       IN    VARCHAR2          -- 03 : �[��
      ,iv_delivery_day_from   IN    VARCHAR2          -- 04 : �o�ɓ�From
      ,iv_delivery_day_to     IN    VARCHAR2          -- 05 : �o�ɓ�To
    )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name   CONSTANT  VARCHAR2(100)   := 'main' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf               VARCHAR2(5000) ;      --   �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1) ;         --   ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000) ;      --   ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ======================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ======================================================
    submain
      (
        iv_delivery_dest      => iv_delivery_dest     -- 01 : �[����
       ,iv_delivery_form      => iv_delivery_form     -- 02 : �o�Ɍ`��
       ,iv_delivery_date      => iv_delivery_date     -- 03 : �[��
       ,iv_delivery_day_from  => iv_delivery_day_from -- 04 : �o�ɓ�From
       ,iv_delivery_day_to    => iv_delivery_day_to   -- 05 : �o�ɓ�To
       ,ov_errbuf             => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode            => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg             => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
  END main ;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxwsh920004c;
/