CREATE OR REPLACE PACKAGE BODY xxpo_common2_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxpo_common2_pkg(BODY)
 * Description            : ���ʊ֐�(�L���x���p)(BODY)
 * MD.070(CMD.050)        : T_MD050_BPO_140_���ʊ֐��i�⑫�����j.xls
 * Version                : 1.2
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  update_order_data         F    N     �S�����o�� ���o�Ɏ��ѓo�^����
 *  get_unit_price            F    N     ���i�\�P���擾����
 *  update_order_unit_price   P    -     �󒍖��׃A�h�I���P���X�V����
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/03/12   1.0   D.Nihei         �V�K�쐬
 *  2008/05/29   1.0   D.Nihei         �����e�X�g�s��Ή�(�S���o�Ɏ��X�e�[�^�X�X�V���)
 *  2008/07/18   1.1   D.Nihei         ST#445�Ή�
 *  2010/09/22   1.2   H.Sasaki        [E_�{�ғ�_02515]�o�ד��A���ד��̍X�V�����ǉ�
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxpo_common2_pkg'; -- �p�b�P�[�W��
--
  gn_ret_nomal     CONSTANT NUMBER := 0; -- ����
  gn_ret_error     CONSTANT NUMBER := 1; -- �G���[
--
  gc_application_po    CONSTANT VARCHAR2(4)  := 'XXPO'; -- �A�v���P�[�V�����iXXPO�j
  gv_xxpo_10200        CONSTANT VARCHAR2(14) := 'APP-XXPO-10200'; --�P���擾�G���[
  gv_xxpo_10201        CONSTANT VARCHAR2(14) := 'APP-XXPO-10201'; --���׍X�V�G���[
  gv_tkn_item          CONSTANT VARCHAR2(4) := 'ITEM'; --�g�[�N����
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
   /**********************************************************************************
   * Function Name    : update_order_data
   * Description      : �S�����o�� ���o�Ɏ��ѓo�^����
   ***********************************************************************************/
  FUNCTION update_order_data(
       in_order_header_id    IN  NUMBER         -- �󒍃w�b�_�A�h�I��ID
      ,iv_record_type_code   IN  VARCHAR2       -- ���R�[�h�^�C�v(20�F�o�Ɏ��сA30�F���Ɏ���)
      ,id_actual_date        IN  DATE           -- ���ѓ�(���ɓ��E�o�ɓ�)
      ,in_created_by         IN  NUMBER         -- �쐬��
      ,id_creation_date      IN  DATE           -- �쐬��
      ,in_last_updated_by    IN  NUMBER         -- �ŏI�X�V��
      ,id_last_update_date   IN  DATE           -- �ŏI�X�V��
      ,in_last_update_login  IN  NUMBER         -- �ŏI�X�V���O�C��
   ) 
  RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'update_order_data'; --�v���O������
  BEGIN
--
    -- ===============================
    -- �ړ����b�g�ڍדo�^
    -- ===============================
    -- �p�����[�^�̎󒍃w�b�_�A�h�I��ID�ɕR�t���ړ����b�g�ڍׂ̃��R�[�h�^�C�v�u10�F�w���v�̃f�[�^��
    -- ���ɁE�o�Ɏ��тƂ��ēo�^����B
    INSERT INTO xxinv_mov_lot_details                                              -- �ړ����b�g�ڍ�
              ( mov_lot_dtl_id                                                     -- ���b�g�ڍ�ID
               ,mov_line_id                                                        -- ����ID
               ,document_type_code                                                 -- �����^�C�v
               ,record_type_code                                                   -- ���R�[�h�^�C�v
               ,item_id                                                            -- OPM�i��ID
               ,item_code                                                          -- �i��
               ,lot_id                                                             -- ���b�gID
               ,lot_no                                                             -- ���b�gNo
               ,actual_date                                                        -- ���ѓ�
               ,actual_quantity                                                    -- ���ѐ���
               ,created_by                                                         -- �쐬��
               ,creation_date                                                      -- �쐬��
               ,last_updated_by                                                    -- �ŏI�X�V��
               ,last_update_date                                                   -- �ŏI�X�V��
               ,last_update_login )                                                -- �ŏI�X�V���O�C��
        SELECT  xxinv_mov_lot_s1.NEXTVAL                                           -- �ړ����b�g�ڍ׎��ʗp
               ,xola.order_line_id                                                 -- �󒍖��׃A�h�I��ID
               ,xmld.document_type_code                                            -- �����^�C�v
               ,iv_record_type_code                                                -- ���R�[�h�^�C�v
               ,xmld.item_id                                                       -- OPM�i��ID
               ,xmld.item_code                                                     -- �i��
               ,xmld.lot_id                                                        -- ���b�gID
               ,xmld.lot_no                                                        -- ���b�gNo
               ,id_actual_date                                                     -- ���ѓ�
               ,xmld.actual_quantity                                               -- ���ѐ���
               ,in_created_by                                                      -- �쐬��
               ,id_creation_date                                                   -- �쐬��
               ,in_last_updated_by                                                 -- �ŏI�X�V��
               ,id_last_update_date                                                -- �ŏI�X�V��
               ,in_last_update_login                                               -- �ŏI�X�V���O�C��
        FROM    xxinv_mov_lot_details     xmld                                     -- �ړ����b�g�ڍ�
               ,xxwsh_order_headers_all   xoha                                     -- �󒍃w�b�_�A�h�I��
               ,xxwsh_order_lines_all     xola                                     -- �󒍖��׃A�h�I��
        WHERE   xoha.order_header_id    = in_order_header_id
        AND     xola.order_header_id    = xoha.order_header_id
        AND     xmld.mov_line_id        = xola.order_line_id
        AND     xmld.document_type_code = '30'                                     -- �x���w��
        AND     xmld.record_type_code   = '10'                                     -- �w��
    ;
--
    -- ===============================
    -- �󒍖��׃A�h�I���X�V
    -- ===============================
    -- �p�����[�^�̎󒍃w�b�_�A�h�I��ID�ɕR�t���󒍖��׃A�h�I���̏o�׎��ѐ��ʂ��X�V����B
    UPDATE xxwsh_order_lines_all          xola                                     -- �󒍖��׃A�h�I��
    SET    xola.shipped_quantity        = DECODE( iv_record_type_code
                                                 ,'20', xola.quantity              -- �o�׎��ѐ��ʂ𐔗ʂōX�V(�o�Ɏ�)
                                                 ,xola.shipped_quantity )          -- ���Ɏ��͏o�׎��ѐ��ʂ��̂܂�
          ,xola.ship_to_quantity        = DECODE( iv_record_type_code
                                                 ,'30', xola.quantity              -- ���Ɏ��ѐ��ʂ𐔗ʂōX�V(���Ɏ�)
                                                 ,xola.ship_to_quantity )          -- �o�Ɏ��͏o�׎��ѐ��ʂ��̂܂�
          ,xola.last_updated_by         = in_last_updated_by                       -- �ŏI�X�V��
          ,xola.last_update_date        = id_last_update_date                      -- �ŏI�X�V��
          ,xola.last_update_login       = in_last_update_login                     -- �ŏI�X�V���O�C��
    WHERE  xola.order_header_id         = in_order_header_id
-- 2008/07/18 D.Nihei MOD START
--    AND    NVL( xola.delete_flag, 'N' ) = 'N'                                      -- �폜�t���OOFF
    AND    xola.delete_flag = 'N'                                      -- �폜�t���OOFF
-- 2008/07/18 D.Nihei MOD END
    ;
--
    -- ===============================
    -- �󒍃w�b�_�A�h�I���X�V
    -- ===============================
    -- �p�����[�^�̎󒍃w�b�_�A�h�I��ID�̎󒍃w�b�_�A�h�I���̃X�e�[�^�X�E�o�ד����X�V����B
    UPDATE xxwsh_order_headers_all        xoha                                     -- �󒍃w�b�_�A�h�I��
    SET    xoha.req_status              = DECODE( iv_record_type_code
-- 2008/05/29 D.Nihei MOD START
--                                                 ,'20', '04'                       -- �o�׎��ьv���(�o�Ɏ��X�V)
                                                 ,'20', '08'                       -- �o�׎��ьv���(�o�Ɏ��X�V)
-- 2008/05/29 D.Nihei MOD END
                                                 ,xoha.req_status )                -- ���Ɏ��͂��̂܂�
-- == 2010/09/22 V1.2 Modified START ===============================================================
--          ,xoha.shipped_date            = DECODE( iv_record_type_code
--                                                 ,'20', xoha.schedule_ship_date    -- �o�ד����o�ח\����ōX�V
--                                                 ,xoha.shipped_date )
--          ,xoha.arrival_date            = DECODE( iv_record_type_code
--                                                 ,'30', xoha.schedule_arrival_date -- ���ד��𒅉ח\����ōX�V
--                                                 ,xoha.arrival_date )
          ,xoha.shipped_date            = CASE  WHEN  iv_record_type_code = '20' AND xoha.shipped_date IS NULL THEN xoha.schedule_ship_date
                                                ELSE  xoha.shipped_date
                                          END   -- �o�ד����ݒ�̏ꍇ�A�o�ח\����ōX�V
          ,xoha.arrival_date            = CASE  WHEN  iv_record_type_code = '30' AND xoha.arrival_date IS NULL THEN xoha.schedule_arrival_date
                                                ELSE  xoha.arrival_date
                                          END   -- ���ד����ݒ�̏ꍇ�A���ח\����ōX�V
-- == 2010/09/22 V1.2 Modified END   ===============================================================
-- 2008/07/18 D.Nihei ADD START
          ,xoha.result_freight_carrier_id   = DECODE( iv_record_type_code
                                                     ,'20', xoha.career_id                      -- �S���o�ɂ̏ꍇ�A�^���Ǝ�_����ID���^���Ǝ�ID�ōX�V
                                                     ,xoha.result_freight_carrier_id )          -- �S�����ɂ̏ꍇ�A�X�V�ΏۊO
          ,xoha.result_freight_carrier_code = DECODE( iv_record_type_code
                                                     ,'20', xoha.freight_carrier_code           -- �S���o�ɂ̏ꍇ�A�^���Ǝ�_���т��^���Ǝ҂ōX�V
                                                     ,xoha.result_freight_carrier_code )        -- �S�����ɂ̏ꍇ�A�X�V�ΏۊO
          ,xoha.result_shipping_method_code = DECODE( iv_record_type_code
                                                     ,'20', xoha.shipping_method_code           -- �S���o�ɂ̏ꍇ�A�z���敪_���т�z���敪�ōX�V
                                                     ,xoha.result_shipping_method_code )        -- �S�����ɂ̏ꍇ�A�X�V�ΏۊO
-- 2008/07/18 D.Nihei ADD START
          ,xoha.last_updated_by         = in_last_updated_by                       -- �ŏI�X�V��
          ,xoha.last_update_date        = id_last_update_date                      -- �ŏI�X�V��
          ,xoha.last_update_login       = in_last_update_login                     -- �ŏI�X�V���O�C��
    WHERE  xoha.order_header_id         = in_order_header_id
    ;
--
    --�X�e�[�^�X�Z�b�g
    RETURN gn_ret_nomal;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
      RETURN gn_ret_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_order_data;
--
   /**********************************************************************************
   * Function Name    : get_unit_price
   * Description      : ���i�\�P���擾����
   ***********************************************************************************/
  FUNCTION get_unit_price(
    in_inventory_item_id  IN  NUMBER         -- INV�i��ID
   ,iv_list_id_vendor     IN  VARCHAR2       -- �����ʉ��i�\ID
   ,iv_list_id_represent  IN  VARCHAR2       -- ��\���i�\ID
   ,id_arrival_date       IN  DATE           -- �K�p��(���ɓ�)
  )
  RETURN NUMBER
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'get_unit_price'; --�v���O������
    cv_product_attr         CONSTANT VARCHAR2(18)  := 'PRICING_ATTRIBUTE1';
    cv_product_attr_ctxt    CONSTANT VARCHAR2(4)   := 'ITEM';
    cv_tkn_item             CONSTANT VARCHAR2(4)   := 'ITEM';
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_unit_price           NUMBER;
    lb_get_represent        BOOLEAN;
    lb_get_vendor           BOOLEAN;
--
    --�p�����[�^�i�[�p���R�[�h
    TYPE lt_prm IS RECORD(
      inventory_item_id     NUMBER
     ,list_id_vendor        VARCHAR2(1000)
     ,list_id_represent     VARCHAR2(1000)
     ,arrival_date          DATE
    );
    lr_prm                lt_prm;
--
    -- ===============================
    -- ���[�J���t�@���N�V����
    -- ===============================
    FUNCTION get_operand(
      in_list_header_id  IN  NUMBER
     ,in_inventory_item_id IN NUMBER
     ,id_arrival_date IN DATE
    )
    RETURN NUMBER
    IS
      ln_list_header_id      NUMBER;
      ln_inventory_item_id   NUMBER;
      ld_arrival_date        DATE;
    BEGIN
      --�p�����[�^�i�[
      ln_list_header_id := in_list_header_id;
      ln_inventory_item_id := in_inventory_item_id;
      ld_arrival_date := id_arrival_date;
--
      --�p�����[�^�`�F�b�N
      IF (ln_list_header_id IS NOT NULL
        AND ln_inventory_item_id IS NOT NULL
        AND ld_arrival_date IS NOT NULL
      ) THEN
        NULL;
      ELSE
        --�����͂̃p�����[�^������ꍇ��NULL��Ԃ��ďI��
        RETURN NULL;
      END IF;
--
      --���i�\����P���擾
      SELECT qll.operand              operand   -- �P��
      INTO ln_unit_price
      FROM   qp_list_lines            qll       -- ���i�\����
            ,qp_pricing_attributes    qpa       -- ���i�\���׏ڍ�
      -- ��������
      WHERE qpa.list_header_id = qll.list_header_id
      AND qpa.list_line_id = qll.list_line_id
      AND qpa.pricing_phase_id = qll.pricing_phase_id
      -- ���o����
      AND qll.list_header_id = ln_list_header_id                     -- ���i�\ID
      AND ld_arrival_date
        BETWEEN NVL(qll.start_date_active,ld_arrival_date)           -- �K�p�J�n��
        AND NVL(qll.end_date_active,ld_arrival_date)                 -- �K�p�I����
      AND qpa.product_attr_value = TO_CHAR(ln_inventory_item_id)     -- INV�i��ID
      AND qpa.product_attribute = cv_product_attr
      AND qpa.product_attribute_context = cv_product_attr_ctxt
      ;
--
      RETURN ln_unit_price;
--
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END get_operand;
--
  BEGIN
--  
    -- ������
    ln_unit_price := NULL;
    lb_get_represent := FALSE;
--
    --�p�����[�^�i�[
    lr_prm.inventory_item_id := in_inventory_item_id;
    lr_prm.list_id_vendor := iv_list_id_vendor;
    lr_prm.list_id_represent := iv_list_id_represent;
    lr_prm.arrival_date := id_arrival_date;
--
    IF (lr_prm.list_id_vendor IS NULL) THEN    -- ����承�i�\ID���Z�b�g����Ȃ������ꍇ
      lb_get_represent := TRUE;
    ELSE                                       -- ����承�i�\ID���Z�b�g���ꂽ�ꍇ
      DECLARE
        ln_list_id  NUMBER;
      BEGIN
        -- ����承�i�\ID�̒l�`�F�b�N
        ln_list_id := TO_NUMBER(lr_prm.list_id_vendor);
        lb_get_vendor := TRUE;
      EXCEPTION
        WHEN OTHERS THEN
          -- NUMBER�^�ɕϊ��ł��Ȃ��ꍇ�͎���承�i�\ID�ł͂Ȃ���\���i�\ID�Ō���
          lb_get_vendor := FALSE;
          lb_get_represent := TRUE;
      END;
    END IF;
--
    IF (lb_get_vendor) THEN
      --����承�i�\ID�ŒP�����擾
      ln_unit_price := get_operand(
                         TO_NUMBER(lr_prm.list_id_vendor)
                        ,lr_prm.inventory_item_id
                        ,lr_prm.arrival_date
                       );
      IF (ln_unit_price IS NULL) THEN
        lb_get_represent := TRUE;
      END IF;
    END IF;
--
    IF (lb_get_represent) THEN    -- ����承�i�\ID�ŒP�����擾�ł��Ȃ������ꍇ
        --��\���i�\ID�ŒP�����擾
        ln_unit_price := get_operand(
                           TO_NUMBER(lr_prm.list_id_represent)
                          ,lr_prm.inventory_item_id
                          ,lr_prm.arrival_date
                         );
    END IF;
--
    RETURN ln_unit_price;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      RETURN NULL;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_unit_price;
--
   /**********************************************************************************
   * Procedure Name   : update_order_unit_price
   * Description      : �󒍖��׃A�h�I���P���X�V����
   ***********************************************************************************/
  PROCEDURE update_order_unit_price(
    in_order_header_id    IN  xxwsh_order_lines_all.order_header_id%TYPE     -- �󒍃w�b�_�A�h�I��ID
   ,iv_list_id_vendor     IN  VARCHAR2                                       -- �����ʉ��i�\ID
   ,iv_list_id_represent  IN  VARCHAR2                                       -- ��\���i�\ID
   ,id_arrival_date       IN  xxwsh_order_headers_all.arrival_date%TYPE      -- �K�p��(���ɓ�)
   ,iv_return_flag        IN  VARCHAR2                                       -- �ԕi�t���O
   ,iv_item_class_code    IN  xxcmn_item_categories2_v.segment1%TYPE         -- �i�ڋ敪
   ,iv_item_no            IN  xxcmn_item_categories2_v.item_no%TYPE          -- OPM�i�ڃR�[�h
   ,ov_retcode            OUT NOCOPY VARCHAR2                                -- �G���[�R�[�h
   ,ov_errmsg             OUT NOCOPY VARCHAR2                                -- �G���[���b�Z�[�W
   ,ov_system_msg         OUT NOCOPY VARCHAR2                                -- �V�X�e�����b�Z�[�W
  ) IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'update_order_unit_price'; --�v���O������
    cv_err_id_text          CONSTANT VARCHAR2(13)  := 'ORDER_LINE_ID';
    cv_err_msg_text         CONSTANT VARCHAR2(7)   := 'SQLERRM';
    cv_text_left            CONSTANT VARCHAR2(1)   := '[';
    cv_text_right           CONSTANT VARCHAR2(1)   := ']';
    cv_text_description     CONSTANT VARCHAR2(12)  := '���i�\���o�^';
    cv_text_item            CONSTANT VARCHAR2(10)  := '�i�ڃR�[�h';
    cv_text_vendor          CONSTANT VARCHAR2(14)  := '����承�i�\ID';
    cv_text_represent       CONSTANT VARCHAR2(12)  := '��\���i�\ID';
    cv_text_date            CONSTANT VARCHAR2(6)   := '�K�p��';
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errmsg             VARCHAR2(5000);
    lv_systemmsg          VARCHAR2(5000);
    lb_get_unit_price     BOOLEAN;
    ln_unit_price         xxwsh_order_lines_all.unit_price%TYPE;
    lv_item_no            xxwsh_order_lines_all.shipping_item_code%TYPE;
    ln_cnt                NUMBER;
--
    --�p�����[�^�i�[�p���R�[�h
    TYPE lt_prm IS RECORD(
      order_header_id     xxwsh_order_lines_all.order_header_id%TYPE --�󒍃w�b�_�A�h�I��ID
     ,list_id_vendor      VARCHAR2(1000) --�����ʉ��i�\ID
     ,list_id_represent   VARCHAR2(1000) --��\���i�\ID
     ,arrival_date        xxwsh_order_headers_all.arrival_date%TYPE --�K�p��(���ɓ�)
     ,return_flag         VARCHAR2(10) --�ԕi�t���O
     ,item_class_code     xxcmn_item_categories2_v.segment1%TYPE --�i�ڋ敪
     ,item_no             xxcmn_item_categories2_v.item_no%TYPE --OPM�i�ڃR�[�h
    );
    lr_prm                lt_prm;
--
    --�󒍖��׃A�h�I���i�[�p���R�[�h
    TYPE lt_order_line IS RECORD(
      order_line_id       xxwsh_order_lines_all.order_line_id%TYPE --�󒍖��׃A�h�I��ID
     ,unit_price          xxwsh_order_lines_all.unit_price%TYPE --�P��
     ,inventory_item_id   xxwsh_order_lines_all.shipping_inventory_item_id%TYPE --�o�וi��ID
     ,item_no             xxwsh_order_lines_all.shipping_item_code%TYPE --�o�וi��
    );
    lr_order_line         lt_order_line;
--
    -- ===============================
    -- ���[�J���J�[�\��
    -- ===============================
    TYPE lt_ref IS REF CURSOR;
    cur_order_line     lt_ref;
--
    -- ===============================
    -- ���[�J����O
    -- ===============================
    get_unit_price_exception   EXCEPTION;
--
  BEGIN
    --��������
    ov_errmsg := NULL;
    ov_system_msg := NULL;
    lr_prm.order_header_id := in_order_header_id;                              --�󒍃w�b�_�A�h�I��ID
    lr_prm.list_id_vendor := iv_list_id_vendor;                                --�����ʉ��i�\ID
    lr_prm.list_id_represent := iv_list_id_represent;                          --��\���i�\ID
    lr_prm.arrival_date := id_arrival_date;                                    --�K�p��(���ɓ�)
    lr_prm.return_flag := iv_return_flag;                                      --�ԕi�t���O
    lr_prm.item_class_code := iv_item_class_code;                              --�i�ڋ敪
    lr_prm.item_no := iv_item_no;                                              --OPM�i�ڃR�[�h
--
    --�i�ڋ敪�AOPM�i�ڃR�[�h�̎w�肪�����ꍇ
    IF (lr_prm.item_class_code IS NULL AND lr_prm.item_no IS NULL) THEN
      OPEN cur_order_line FOR
        SELECT xola.order_line_id                                              --�󒍖��׃A�h�I��ID
              ,xola.unit_price                                                 --�P��
              ,xola.shipping_inventory_item_id                                 --�o�וi��ID
              ,xola.shipping_item_code                                         --�o�וi��
        FROM   xxwsh_order_lines_all xola                                      --�󒍖��׃A�h�I��
        WHERE  xola.order_header_id = lr_prm.order_header_id                   --�󒍃w�b�_�A�h�I��ID
        AND    NVL(xola.delete_flag,'N') = 'N'                                 --�폜�t���O
        ORDER BY xola.order_line_number                                        --�󒍖��הԍ�
        ;
--
    --OPM�i�ڃR�[�h���w�肳�ꂽ�ꍇ
    ELSIF (lr_prm.item_no IS NOT NULL) THEN
      OPEN cur_order_line FOR
        SELECT xola.order_line_id                                              --�󒍖��׃A�h�I��ID
              ,xola.unit_price                                                 --�P��
              ,xola.shipping_inventory_item_id                                 --�o�וi��ID
              ,xola.shipping_item_code                                         --�o�וi��
        FROM   xxwsh_order_lines_all xola                                      --�󒍖��׃A�h�I��
        WHERE  xola.order_header_id = lr_prm.order_header_id                   --�󒍃w�b�_�A�h�I��ID
        AND    NVL(xola.delete_flag,'N') = 'N'                                 --�폜�t���O
        AND    xola.shipping_item_code = lr_prm.item_no                        --�o�וi��
        ORDER BY xola.order_line_number                                        --�󒍖��הԍ�
        ;
--
    --OPM�i�ڃR�[�h���w�肳�ꂸ�A�i�ڋ敪���w�肳�ꂽ�ꍇ
    ELSIF (lr_prm.item_class_code IS NOT NULL) THEN
      OPEN cur_order_line FOR
        SELECT xola.order_line_id                                              --�󒍖��׃A�h�I��ID
              ,xola.unit_price                                                 --�P��
              ,xola.shipping_inventory_item_id                                 --�o�וi��ID
              ,xola.shipping_item_code                                         --�o�וi��
        FROM   xxwsh_order_lines_all xola                                      --�󒍖��׃A�h�I��
              ,xxcmn_item_categories2_v xicv                                   --�i�ڃJ�e�S�����view2
        WHERE  xola.order_header_id = lr_prm.order_header_id                   --�󒍃w�b�_�A�h�I��ID
        AND    NVL(xola.delete_flag,'N') = 'N'                                 --�폜�t���O
        AND    xicv.item_no = xola.shipping_item_code                          --�i�ڃR�[�h
        AND    xicv.category_set_name = '�i�ڋ敪'                             --�J�e�S���Z�b�g��
        AND    xicv.segment1 = lr_prm.item_class_code                          --�i�ڋ敪
        ORDER BY xola.order_line_number                                        --�󒍖��הԍ�
        ;
    END IF;
--
    ln_cnt := 0;
--
    <<line_loop>>
    LOOP
      FETCH cur_order_line INTO lr_order_line;
      EXIT WHEN cur_order_line%NOTFOUND;
--
      --����������
      lb_get_unit_price := FALSE;
      ln_cnt := ln_cnt + 1;
--
      --�ԕi�̏ꍇ
      IF (lr_prm.return_flag = 'Y') THEN
        --�P���������͂̏ꍇ
        IF (lr_order_line.unit_price IS NULL) THEN
          --�P���擾�������s��
          lb_get_unit_price := TRUE;
        END IF;
      --�ԕi�ł͂Ȃ��ꍇ
      ELSE
        --�P���擾�������s��
        lb_get_unit_price := TRUE;
      END IF;
--
      IF (lb_get_unit_price) THEN
        --���i�\����P���擾
        ln_unit_price := get_unit_price(
                           lr_order_line.inventory_item_id                     --�i��ID
                          ,lr_prm.list_id_vendor                               --�����ʉ��i�\ID
                          ,lr_prm.list_id_represent                            --��\���i�\ID
                          ,lr_prm.arrival_date                                 --�K�p��(���ɓ�)
                         );
--
        --�P����NULL�̏ꍇ
        IF (ln_unit_price IS NULL) THEN
          --�P���擾�G���[
          lv_item_no := lr_order_line.item_no;
          CLOSE cur_order_line;
--
          RAISE get_unit_price_exception;
        --�P�����Ԃ��ꂽ�ꍇ
        ELSE
          --���݂̒P���Ɖ��i�\�̒P���������ꍇ�͍X�V���X�L�b�v����
          --�˕i�ڃR�[�h���G���[���b�Z�[�W�ɃZ�b�g
          IF (lr_order_line.unit_price = ln_unit_price) THEN
            ov_errmsg := lr_order_line.item_no;
          --���݂̒P���Ɖ��i�\�̒P�����قȂ�ꍇ�͍X�V����
          ELSE
            UPDATE xxwsh_order_lines_all xola                                --�󒍖��׃A�h�I��
            SET xola.unit_price = ln_unit_price                              --�P��=���i�\�̒P��
               ,xola.last_updated_by = fnd_global.user_id                    --�ŏI�X�V��
               ,xola.last_update_date = SYSDATE                              --�ŏI�X�V��
               ,xola.last_update_login = fnd_global.login_id                 --�ŏI�X�V���O�C��
               --�ȉ��A�R���J�����g������s���ꂽ�ꍇ��FND_GLOBAL�̒l�ōX�V
               ,xola.request_id                                              --�v��ID
                = DECODE(fnd_global.conc_request_id
                           ,-1,xola.request_id
                              ,fnd_global.conc_request_id)
               ,xola.program_application_id                                  --�v���O�����A�v���P�[�V����ID
                = DECODE(fnd_global.conc_request_id
                           ,-1,xola.program_application_id
                              ,fnd_global.prog_appl_id)
               ,xola.program_id                                              --�v���O����ID
                 = DECODE(fnd_global.conc_request_id
                           ,-1,xola.program_id
                              ,fnd_global.conc_program_id)
               ,xola.program_update_date                                     --�v���O�����X�V��
                = DECODE(fnd_global.conc_request_id
                           ,-1,xola.program_update_date
                           ,SYSDATE)
            WHERE xola.order_line_id = lr_order_line.order_line_id           --�󒍖��׃A�h�I��ID
            ;
          END IF;
        END IF;
      END IF;
    END LOOP line_loop;
    CLOSE cur_order_line;
--
    --����I��
    IF (ln_cnt > 0) THEN
      ov_retcode := gv_status_normal;
    ELSE
      ov_retcode := gv_status_warn;
    END IF;
--
  EXCEPTION
    -- *** �P���擾��O�n���h�� ***
    WHEN get_unit_price_exception THEN
      ov_retcode := gv_status_error;
      ov_errmsg := lv_item_no;
      ov_system_msg := SUBSTRB(gv_pkg_name || gv_msg_cont || cv_prg_name || gv_msg_part || 
                               cv_text_description || ' ' ||
                               cv_text_item || cv_text_left || ov_errmsg  || cv_text_right || ' ' ||
                               cv_text_vendor || cv_text_left || iv_list_id_vendor  || cv_text_right || ' ' ||
                               cv_text_represent || cv_text_left || iv_list_id_represent  || cv_text_right || ' ' ||
                               cv_text_date || cv_text_left || TO_CHAR(id_arrival_date,'YYYY/MM/DD')  || cv_text_right
                               , 1, 5000);
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF cur_order_line%ISOPEN THEN
        CLOSE cur_order_line;
      END IF;
--
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_order_unit_price;
--
END xxpo_common2_pkg;
/
