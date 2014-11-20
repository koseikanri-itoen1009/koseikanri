CREATE OR REPLACE VIEW APPS.XXSKY_��������w�b�__��{_V
(
 �����ԍ�
,����ԕi�ԍ�
,�X�e�[�^�X
,�X�e�[�^�X��
,�w���S���Ҕԍ�
,�w���S���Җ�
,�d����R�[�h
,�d���於
,�d����T�C�g�R�[�h
,�d����T�C�g��
,�����掖�Ə��R�[�h
,�����掖�Ə���
,�����掖�Ə��R�[�h
,�����掖�Ə���
,�d���揳���v�t���O
,�d���揳���v�t���O��
,�����҃R�[�h
,�����Җ�
,�[����
,�[����R�[�h
,�[���於
,�����敪
,�����敪��
,�z����R�[�h
,�z���於
,�˗��ԍ�
,�����R�[�h
,������
,�����敪
,�����敪��
,�w�b�_�E�v
,�g�D��
,�˗��҃R�[�h
,�˗��Җ�
,�˗��ҕ����R�[�h
,�˗��ҕ�����
,�˗��敔���R�[�h
,�˗��敔����
,�˗���
,���������t���O
,�������F�t���O��
,���������Ҕԍ�
,���������Җ�
,�����������t
,�d�������t���O
,�d�������t���O��
,�d���������[�U�[�ԍ�
,�d���������[�U�[��
,�d���������t
,�ύX�t���O
,�ύX�t���O��
,����_�쐬��
,����_�쐬��
,����_�ŏI�X�V��
,����_�ŏI�X�V��
,����_�ŏI�X�V���O�C��
,���_���ы敪
,���_���ы敪��
,���_�x���˗��ԍ�
,���_�����R�[�h
,���_����於
,���_�H��R�[�h
,���_�H�ꖼ
,���_���o�ɐ�R�[�h
,���_���o�ɐ於
,�ԕi�w�b�_�E�v
)
AS
SELECT
        POH.po_number                                       po_number                     --�����ԍ�
       ,POH.rcv_rtn_number                                  rcv_rtn_number                --����ԕi�ԍ��iNULL�ł����������Ƃ��Ďg�p����� 'Dummy' �ŕ\���j
       ,POH.status                                          status                        --�X�e�[�^�X
       ,POH.status_name                                     status_name                   --�X�e�[�^�X��
       ,PAPF1.employee_number                               po_charge                     --�w���S���Ҕԍ�
       ,REPLACE( PAPF1.per_information18, CHR(9) )          po_charge_name                --�w���S���Җ�(�^�u�����Ή�)
       ,VNDR1.segment1                                      vendor_code                   --�d����R�[�h
       ,VNDR1.vendor_name                                   vendor_name                   --�d���於
       ,VDST1.vendor_site_code                              vendor_site_code              --�d����T�C�g�R�[�h
       ,VDST1.vendor_site_name                              vendor_site_name              --�d����T�C�g��
       ,LOCT1.location_code                                 ship_to_loct_code             --�����掖�Ə��R�[�h
       ,LOCT1.location_name                                 ship_to_loct_name             --�����掖�Ə���
       ,LOCT2.location_code                                 bill_to_loct_code             --���掖�Ə��R�[�h
       ,LOCT2.location_name                                 bill_to_loct_name             --�����掖�Ə���
       ,POH.vendor_approved_flg                             vendor_approved_flg           --�d���揳���t���O
       ,CASE WHEN POH.vendor_approved_flg = 'Y' THEN '�K�v'
             WHEN POH.vendor_approved_flg = 'N' THEN '�s�v'
        END                                                 vendor_approved_flg_name      --�d���揳���t���O��
       ,VNDR2.segment1                                      assist_code                   --�����҃R�[�h
       ,VNDR2.vendor_name                                   assist_name                   --�����Җ�
       ,POH.deliver_date                                    deliver_date                  --�[����
       ,POH.deliver_in                                      deliver_in                    --�[����R�[�h
       ,ILOC1.description                                   deliver_in_name               --�[���於
       ,POH.drop_ship_type                                  drop_ship_type                --�����敪
       ,FLV01.meaning                                       drop_ship_type_name           --�����敪��
       ,POH.deliver_to                                      deliver_to                    --�z����R�[�h
       ,DELV.name                                           deliver_to_name               --�z���於
       ,POH.request_no                                      request_no                    --�˗��ԍ�
       ,POH.dept_code                                       dept_code                     --�����R�[�h
       ,LOCT3.location_name                                 dept_name                     --������
       ,POH.po_type                                         po_type                       --�����敪
       ,FLV02.meaning                                       po_type_name                  --�����敪��
       ,POH.h_header_desc                                   h_header_desc                 --�w�b�_�E�v
       ,HAOUT.name                                          org_name                      --�g�D��
       ,POH.requested_by_code                               requested_by_code             --�˗��҃R�[�h
       ,REPLACE( PAPF2.per_information18, CHR(9) )          requested_by_name             --�˗��Җ�(�^�u�����Ή�)
       ,POH.requested_dept_code                             requested_dept_code           --�˗��ҕ����R�[�h
       ,LOCT4.location_name                                 requested_dept_name           --�˗��ҕ�����
       ,POH.requested_to_dept_code                          requested_to_dept_code        --�˗��敔���R�[�h
       ,LOCT5.location_name                                 requested_to_dept_name        --�˗��敔����
       ,POH.requested_date                                  requested_date                --�˗���
       ,POH.order_approved_flg                              order_approved_flg            --���������t���O
       ,CASE WHEN POH.order_approved_flg = 'Y' THEN '���F��'
             WHEN POH.order_approved_flg = 'N' THEN '�����F'
        END                                                 order_approved_flg_name       --���������t���O��
       ,PAPF3.employee_number                               order_approved_code           --���������Ҕԍ�
       ,REPLACE( PAPF3.per_information18, CHR(9) )          order_approved_name           --���������Җ�(�^�u�����Ή�)
       ,POH.order_approved_date                             order_approved_date           --�����������t
       ,POH.purchase_approved_flg                           purchase_approved_flg         --�d�������t���O
       ,CASE WHEN POH.purchase_approved_flg = 'Y' THEN '���F��'
             WHEN POH.purchase_approved_flg = 'N' THEN '�����F'
        END                                                 purchase_approved_flg_name    --�d�������t���O��
       ,PAPF4.employee_number                               purchase_approved_code        --�d�������Ҕԍ�
       ,REPLACE( PAPF4.per_information18, CHR(9) )          purchase_approved_name        --�d�������Җ�(�^�u�����Ή�)
       ,POH.purchase_approved_date                          purchase_approved_date        --�d���������t
       ,POH.change_flag                                     change_flg                    --�ύX�t���O
       ,CASE WHEN POH.change_flag = 'Y' THEN '�ύX����'
             WHEN POH.change_flag = 'N' THEN '�ύX�Ȃ�'
        END                                                 change_flg_name               --�ύX�t���O��
       ,FU_CB_H.user_name                                   h_created_by                  --����_�쐬��
       ,TO_CHAR( POH.h_creation_date   , 'YYYY/MM/DD HH24:MI:SS' )
                                                            h_creation_date               --����_�쐬��
       ,FU_LU_H.user_name                                   h_last_updated_by             --����_�ŏI�X�V��
       ,TO_CHAR( POH.h_last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                                            h_last_update_date            --����_�ŏI�X�V��
       ,FU_LL_H.user_name                                   h_last_update_login           --����_�ŏI�X�V���O�C��
       ,POH.u_txns_type                                     u_txns_type                   --���_���ы敪
       ,FLV03.meaning                                       u_txns_type_name              --���_���ы敪��
       ,POH.u_supply_requested_no                           u_supply_requested_no         --���_�x���˗��ԍ�
       ,POH.u_vendor_code                                   u_vendor_code                 --���_�����R�[�h
       ,VNDR3.vendor_name                                   u_vendor_name                 --���_����於
       ,POH.u_factory_code                                  u_factory_code                --���_�H��R�[�h
       ,VDST2.vendor_site_name                              u_factory_name                --���_�H�ꖼ
       ,POH.u_loct_code                                     u_loct_code                   --���_���o�ɐ�R�[�h
       ,ILOC2.description                                   u_loct_name                   --���_���o�ɐ於
       ,POH.u_header_desc                                   u_header_desc                 --�ԕi�w�b�_�E�v
  FROM
       ( --�y�����˗��z�y��������z�y��������ԕi�z�y���������ԕi�z �̊e�f�[�^���擾
          --========================================================================
          -- �����˗��f�[�^ �i�����˗��f�[�^ NOT EXISTS �����f�[�^�j
          --========================================================================
          SELECT
                  XRH.po_header_number                      po_number                     --�����ԍ�
                 ,'Dummy'                                   rcv_rtn_number                --����ԕi�ԍ��i������уf�[�^�����݂��Ȃ��ׂ� 'Dummy' �Œ�j
                 ,XRH.status                                status                        --�X�e�[�^�X
                 ,FLV.meaning                               status_name                   --�X�e�[�^�X��
                 ,NULL                                      pa_agent_id                   --�w���S��ID
                 ,XRH.vendor_id                             vendor_id                     --�d����ID
                 ,XRH.vendor_site_id                        vendor_site_id                --�d����T�C�gID
                 ,NULL                                      ship_to_location_id           --�����掖�Ə�ID
                 ,NULL                                      bill_to_location_id           --�����掖�Ə�ID
                 ,NULL                                      vendor_approved_flg           --�d���揳���v�t���O
                 ,NULL                                      assist_id                     --������ID
                 ,XRH.promised_date                         deliver_date                  --�[����
                 ,XRH.location_code                         deliver_in                    --�[����R�[�h
                 ,XRH.drop_ship_type                        drop_ship_type                --�����敪
                 ,XRH.delivery_code                         deliver_to                    --�z����R�[�h
                 ,NULL                                      request_no                    --�˗��ԍ�
                 ,NULL                                      dept_code                     --�����R�[�h
                 ,NULL                                      po_type                       --�����敪
                 ,XRH.description                           h_header_desc                 --�w�b�_�E�v
                 ,NULL                                      org_id                        --�g�DID
                 ,XRH.requested_by_code                     requested_by_code             --�˗��҃R�[�h
                 ,XRH.requested_dept_code                   requested_dept_code           --�˗��ҕ����R�[�h
                 ,XRH.requested_to_department_code          requested_to_dept_code        --�˗��敔���R�[�h
                 ,NULL                                      requested_date                --�˗���
                 ,NULL                                      order_approved_flg            --���������t���O
                 ,NULL                                      order_approved_by             --����������ID
                 ,NULL                                      order_approved_date           --�����������t
                 ,NULL                                      purchase_approved_flg         --�d�������t���O
                 ,NULL                                      purchase_approved_by          --�d��������ID
                 ,NULL                                      purchase_approved_date        --�d���������t
                 ,XRH.change_flag                           change_flag                   --�ύX�t���O
                 ,XRH.created_by                            h_created_by                  --����_�쐬��
                 ,XRH.creation_date                         h_creation_date               --����_�쐬��
                 ,XRH.last_updated_by                       h_last_updated_by             --����_�ŏI�X�V��
                 ,XRH.last_update_date                      h_last_update_date            --����_�ŏI�X�V��
                 ,XRH.last_update_login                     h_last_update_login           --����_�ŏI�X�V���O�C��
                 ,NULL                                      u_txns_type                   --���_���ы敪
                 ,NULL                                      u_supply_requested_no         --���_�x���˗��ԍ�
                 ,NULL                                      u_vendor_id                   --���_�����ID
                 ,NULL                                      u_vendor_code                 --���_�����R�[�h
                 ,NULL                                      u_factory_id                  --���_�H��ID
                 ,NULL                                      u_factory_code                --���_�H��R�[�h
                 ,NULL                                      u_loct_code                   --���_���o�ɐ�R�[�h
                 ,NULL                                      u_header_desc                 --�ԕi�w�b�_�E�v�i����f�[�^�̃w�b�_�E�v��LOT�P�ʂŋL�ڂ����ׁA�擾���Ȃ��j
            FROM
                  xxpo_requisition_headers                  XRH                           --�����˗��w�b�_(�A�h�I��)
                 ,fnd_lookup_values                         FLV                           --�N�C�b�N�R�[�h(�X�e�[�^�X��)
           WHERE
             -- �����σf�[�^�́w���������f�[�^�x�Ƃ��ĕ\������ׁA���O����
                  NOT EXISTS
                  (
                    SELECT  E_XRH.requisition_header_id
                      FROM  xxpo_requisition_headers        E_XRH                         --�����˗��w�b�_(�A�h�I��)
                           ,po_headers_all                  E_PHA                         --�����w�b�_
                     WHERE  E_XRH.po_header_number          = E_PHA.segment1              --�����ԍ��Ō���
                       AND  E_XRH.requisition_header_id     = XRH.requisition_header_id
                  )
             --�X�e�[�^�X��
             AND  FLV.language(+)                           = 'JA'
             AND  FLV.lookup_type(+)                        = 'XXPO_AUTHORIZATION_STATUS' --���������f�[�^�Ƃ͈قȂ�ׁA�X�Ŏ擾
             AND  FLV.lookup_code(+)                        = XRH.status
          --[ �����˗��f�[�^  END ]
        UNION ALL
          --========================================================================
          -- �����E����f�[�^ �i������ы敪 = '1'�j
          --========================================================================
          SELECT  DISTINCT    -- �ˎ���ԕi�A�h�I���f�[�^�����b�g�P�ʂŃf�[�^�ێ����Ă���ׁA�d���f�[�^�ƂȂ��Ă��܂�
                  PHA.segment1                              po_number                     --�����ԍ�
                 ,NVL( XRART.rcv_rtn_number, 'Dummy' )      rcv_rtn_number                --����ԕi�ԍ��i������уf�[�^�����݂��Ȃ��ꍇ�� 'Dummy' �Œ�j
                 ,PHA.attribute1                            status                        --�X�e�[�^�X
                 ,FLV.meaning                               status_name                   --�X�e�[�^�X��
                 ,PHA.agent_id                              pa_agent_id                   --�w���S��ID
                 ,PHA.vendor_id                             vendor_id                     --�d����ID
                 ,PHA.vendor_site_id                        vendor_site_id                --�d����T�C�gID
                 ,PHA.ship_to_location_id                   ship_to_location_id           --�����掖�Ə�ID
                 ,PHA.bill_to_location_id                   bill_to_location_id           --�����掖�Ə�ID
                 ,PHA.attribute2                            vendor_approved_flg           --�d���揳���v�t���O
                 ,TO_NUMBER( PHA.attribute3 )               assist_id                     --������ID
                 ,TO_DATE( PHA.attribute4 )                 deliver_date                  --�[����
                 ,PHA.attribute5                            deliver_in                    --�[����R�[�h
                 ,PHA.attribute6                            drop_ship_type                --�����敪
                 ,PHA.attribute7                            deliver_to                    --�z����R�[�h
                 ,PHA.attribute9                            request_no                    --�˗��ԍ�
                 ,PHA.attribute10                           dept_code                     --�����R�[�h
                 ,PHA.attribute11                           po_type                       --�����敪
                 ,PHA.attribute15                           h_header_desc                 --�w�b�_�E�v
                 ,TO_NUMBER( PHA.org_id )                   org_id                        --�g�DID
                 ,XHA.requested_by_code                     requested_by_code             --�˗��҃R�[�h
                 ,XHA.requested_department_code             requested_dept_code           --�˗��ҕ����R�[�h
                 ,XRH.requested_to_department_code          requested_to_dept_code        --�˗��敔���R�[�h
                 ,XHA.requested_date                        requested_date                --�˗���
                 ,XHA.order_approved_flg                    order_approved_flg            --���������t���O
                 ,XHA.order_approved_by                     order_approved_by             --����������ID
                 ,XHA.order_approved_date                   order_approved_date           --�����������t
                 ,XHA.purchase_approved_flg                 purchase_approved_flg         --�d�������t���O
                 ,XHA.purchase_approved_by                  purchase_approved_by          --�d��������ID
                 ,XHA.purchase_approved_date                purchase_approved_date        --�d���������t
                 ,NULL                                      change_flag                   --�ύX�t���O
                 ,XHA.created_by                            h_created_by                  --����_�쐬��
                 ,XHA.creation_date                         h_creation_date               --����_�쐬��
                 ,XHA.last_updated_by                       h_last_updated_by             --����_�ŏI�X�V��
                 ,XHA.last_update_date                      h_last_update_date            --����_�ŏI�X�V��
                 ,XHA.last_update_login                     h_last_update_login           --����_�ŏI�X�V���O�C��
                 ,XRART.txns_type                           u_txns_type                   --���_���ы敪
                 ,XRART.supply_requested_number             u_supply_requested_no         --���_�x���˗��ԍ�
                 ,XRART.vendor_id                           u_vendor_id                   --���_�����ID
                 ,XRART.vendor_code                         u_vendor_code                 --���_�����R�[�h
                 ,XRART.factory_id                          u_factory_id                  --���_�H��ID
                 ,XRART.factory_code                        u_factory_code                --���_�H��R�[�h
                 ,XRART.location_code                       u_loct_code                   --���_���o�ɐ�R�[�h
                 ,NULL                                      u_header_desc                 --�ԕi�w�b�_�E�v�i����f�[�^�̃w�b�_�E�v��LOT�P�ʂŋL�ڂ����ׁA�擾���Ȃ��j
            FROM
                  po_headers_all                            PHA                           --�����w�b�_
                 ,xxpo_headers_all                          XHA                           --�����w�b�_�A�h�I��
                 ,xxpo_rcv_and_rtn_txns                     XRART                         --����ԕi���уA�h�I��
                 ,xxpo_requisition_headers                  XRH                           --�����˗��w�b�_�A�h�I��(�˗��敔���R�[�h�擾�p)
                 ,fnd_lookup_values                         FLV                           --�N�C�b�N�R�[�h(�X�e�[�^�X��)
           WHERE
             --�����w�b�_�A�h�I���Ƃ̌���
                  PHA.segment1                              = XHA.po_header_number
             --����ԕi���уA�h�I���Ƃ̌���   �˔����~�܂�i������уf�[�^�����j�̃f�[�^���擾����ׁA�O������
             AND  XRART.txns_type(+)                        = '1'                         --���ы敪:'1:���'
             AND  PHA.segment1                              = XRART.rcv_rtn_number(+)
             --�����˗��w�b�_�A�h�I���Ƃ̌���
             AND  PHA.segment1                              = XRH.po_header_number(+)
             --�X�e�[�^�X��
             AND  FLV.language(+)                           = 'JA'
             AND  FLV.lookup_type(+)                        = 'XXPO_PO_ADD_STATUS'        --�����˗��f�[�^�Ƃ͈قȂ�ׁA�X�Ŏ擾
             AND  FLV.lookup_code(+)                        = PHA.attribute1
          --[ �����˗��f�[�^  END ]
        UNION ALL
          --========================================================================
          -- ��������ԕi�f�[�^ �i������ы敪 = '2'�j
          --========================================================================
          SELECT  DISTINCT    -- �ˎ���ԕi�A�h�I���f�[�^�����b�g�P�ʂŃf�[�^�ێ����Ă���ׁA�d���f�[�^�ƂȂ��Ă��܂�
                  PHA.segment1                              po_number                     --�����ԍ��i��������Ȃ̂Ŕ����ԍ��͕K�����݂���j
                 ,XRART.rcv_rtn_number                      rcv_rtn_number                --����ԕi�ԍ��i�ԕi�f�[�^�Ȃ̂ŕԕi�ԍ����K�����݂���j
                 ,PHA.attribute1                            status                        --�X�e�[�^�X
                 ,FLV.meaning                               status_name                   --�X�e�[�^�X��
                 ,PHA.agent_id                              pa_agent_id                   --�w���S��ID
                 ,PHA.vendor_id                             vendor_id                     --�d����ID
                 ,PHA.vendor_site_id                        vendor_site_id                --�d����T�C�gID
                 ,PHA.ship_to_location_id                   ship_to_location_id           --�����掖�Ə�ID
                 ,PHA.bill_to_location_id                   bill_to_location_id           --�����掖�Ə�ID
                 ,PHA.attribute2                            vendor_approved_flg           --�d���揳���v�t���O
                 ,TO_NUMBER( PHA.attribute3 )               assist_id                     --������ID
                 ,TO_DATE( PHA.attribute4 )                 deliver_date                  --�[����
                 ,PHA.attribute5                            deliver_in                    --�[����R�[�h
                 ,PHA.attribute6                            drop_ship_type                --�����敪
                 ,PHA.attribute7                            deliver_to                    --�z����R�[�h
                 ,PHA.attribute9                            request_no                    --�˗��ԍ�
                 ,PHA.attribute10                           dept_code                     --�����R�[�h
                 ,PHA.attribute11                           po_type                       --�����敪
                 ,PHA.attribute15                           h_header_desc                 --�w�b�_�E�v
                 ,TO_NUMBER( PHA.org_id )                   org_id                        --�g�DID
                 ,XHA.requested_by_code                     requested_by_code             --�˗��҃R�[�h
                 ,XHA.requested_department_code             requested_dept_code           --�˗��ҕ����R�[�h
                 ,XRH.requested_to_department_code          requested_to_dept_code        --�˗��敔���R�[�h
                 ,XHA.requested_date                        requested_date                --�˗���
                 ,XHA.order_approved_flg                    order_approved_flg            --���������t���O
                 ,XHA.order_approved_by                     order_approved_by             --����������ID
                 ,XHA.order_approved_date                   order_approved_date           --�����������t
                 ,XHA.purchase_approved_flg                 purchase_approved_flg         --�d�������t���O
                 ,XHA.purchase_approved_by                  purchase_approved_by          --�d��������ID
                 ,XHA.purchase_approved_date                purchase_approved_date        --�d���������t
                 ,NULL                                      change_flag                   --�ύX�t���O
                 ,XHA.created_by                            h_created_by                  --����_�쐬��
                 ,XHA.creation_date                         h_creation_date               --����_�쐬��
                 ,XHA.last_updated_by                       h_last_updated_by             --����_�ŏI�X�V��
                 ,XHA.last_update_date                      h_last_update_date            --����_�ŏI�X�V��
                 ,XHA.last_update_login                     h_last_update_login           --����_�ŏI�X�V���O�C��
                 ,XRART.txns_type                           u_txns_type                   --���_���ы敪
                 ,XRART.supply_requested_number             u_supply_requested_no         --���_�x���˗��ԍ�
                 ,XRART.vendor_id                           u_vendor_id                   --���_�����ID
                 ,XRART.vendor_code                         u_vendor_code                 --���_�����R�[�h
                 ,XRART.factory_id                          u_factory_id                  --���_�H��ID
                 ,XRART.factory_code                        u_factory_code                --���_�H��R�[�h
                 ,XRART.location_code                       u_loct_code                   --���_���o�ɐ�R�[�h
                 ,XRART.header_description                  u_header_desc                 --�ԕi�w�b�_�E�v�i�ԕi�f�[�^�̏ꍇ�̂ݎ擾����j
            FROM
                  po_headers_all                            PHA                           --�����w�b�_
                 ,xxpo_headers_all                          XHA                           --�����w�b�_�A�h�I��
                 ,xxpo_rcv_and_rtn_txns                     XRART                         --����ԕi���уA�h�I��
                 ,xxpo_requisition_headers                  XRH                           --�����˗��w�b�_�A�h�I��(�˗��敔���R�[�h�擾�p)
                 ,fnd_lookup_values                         FLV                           --�N�C�b�N�R�[�h(�X�e�[�^�X��)
           WHERE
             --�����w�b�_�A�h�I���Ƃ̌���
                  PHA.segment1                              = XHA.po_header_number
             --����ԕi���уA�h�I���Ƃ̌���   �ˊO���������Ȃ�
             AND  XRART.txns_type                           = '2'                         --���ы敪:'2:��������ԕi'
             AND  PHA.segment1                              = XRART.source_document_number
             --�����˗��w�b�_�A�h�I���Ƃ̌���
             AND  PHA.segment1                              = XRH.po_header_number(+)
             --�X�e�[�^�X��
             AND  FLV.language(+)                           = 'JA'
             AND  FLV.lookup_type(+)                        = 'XXPO_PO_ADD_STATUS'        --�����˗��f�[�^�Ƃ͈قȂ�ׁA�X�Ŏ擾
             AND  FLV.lookup_code(+)                        = PHA.attribute1
          --[ ��������ԕi�f�[�^  END ]
        UNION ALL
          --========================================================================
          -- ���������ԕi�f�[�^ �i������ы敪 = '3'�j
          --========================================================================
          SELECT  DISTINCT    -- �ˎ���ԕi�A�h�I���f�[�^�����b�g�P�ʂŃf�[�^�ێ����Ă���ׁA�d���f�[�^�ƂȂ��Ă��܂�
                  'Dummy'                                   po_number                     --�����ԍ��i�����f�[�^�����Ȃ̂� 'Dummy' �Œ�j
                 ,XRART.rcv_rtn_number                      rcv_rtn_number                --����ԕi�ԍ��i�ԕi�f�[�^�Ȃ̂ŕԕi�ԍ����K�����݂���j
                 ,NULL                                      status                        --�X�e�[�^�X
                 ,NULL                                      status_name                   --�X�e�[�^�X��
                 ,NULL                                      pa_agent_id                   --�w���S��ID
                 ,NULL                                      vendor_id                     --�d����ID
                 ,NULL                                      vendor_site_id                --�d����T�C�gID
                 ,NULL                                      ship_to_location_id           --�����掖�Ə�ID
                 ,NULL                                      bill_to_location_id           --�����掖�Ə�ID
                 ,NULL                                      vendor_approved_flg           --�d���揳���v�t���O
                 ,XRART.vendor_id                           assist_id                     --������ID
                 ,XRART.txns_date                           deliver_date                  --�[����
                 ,XRART.location_code                       deliver_in                    --�[����R�[�h
                 ,XRART.drop_ship_type                      drop_ship_type                --�����敪
                 ,XRART.delivery_code                       deliver_to                    --�z����R�[�h
                 ,NULL                                      request_no                    --�˗��ԍ�
                 ,XRART.department_code                     dept_code                     --�����R�[�h
                 ,NULL                                      po_type                       --�����敪
                 ,NULL                                      h_header_desc                 --�w�b�_�E�v
                 ,NULL                                      org_id                        --�g�DID
                 ,NULL                                      requested_by_code             --�˗��҃R�[�h
                 ,NULL                                      requested_dept_code           --�˗��ҕ����R�[�h
                 ,NULL                                      requested_to_dept_code        --�˗��敔���R�[�h
                 ,NULL                                      requested_date                --�˗���
                 ,NULL                                      order_approved_flg            --���������t���O
                 ,NULL                                      order_approved_by             --����������ID
                 ,NULL                                      order_approved_date           --�����������t
                 ,NULL                                      purchase_approved_flg         --�d�������t���O
                 ,NULL                                      purchase_approved_by          --�d��������ID
                 ,NULL                                      purchase_approved_date        --�d���������t
                 ,NULL                                      change_flag                   --�ύX�t���O
                 ,NULL                                      h_created_by                  --����_�쐬��
                 ,NULL                                      h_creation_date               --����_�쐬��
                 ,NULL                                      h_last_updated_by             --����_�ŏI�X�V��
                 ,NULL                                      h_last_update_date            --����_�ŏI�X�V��
                 ,NULL                                      h_last_update_login           --����_�ŏI�X�V���O�C��
                 ,XRART.txns_type                           u_txns_type                   --���_���ы敪
                 ,XRART.supply_requested_number             u_supply_requested_no         --���_�x���˗��ԍ�
                 ,XRART.vendor_id                           u_vendor_id                   --���_�����ID
                 ,XRART.vendor_code                         u_vendor_code                 --���_�����R�[�h
                 ,XRART.factory_id                          u_factory_id                  --���_�H��ID
                 ,XRART.factory_code                        u_factory_code                --���_�H��R�[�h
                 ,XRART.location_code                       u_loct_code                   --���_���o�ɐ�R�[�h
                 ,XRART.header_description                  u_header_desc                 --�ԕi�w�b�_�E�v�i�ԕi�f�[�^�̏ꍇ�̂ݎ擾����j
            FROM
                  xxpo_rcv_and_rtn_txns                     XRART                         --����ԕi���уA�h�I��
           WHERE
                  XRART.txns_type                           = '3'                         --���ы敪:'3:���������ԕi'
          --[ ���������ԕi�f�[�^  END ]
       )                                          POH                           --��������w�b�_�f�[�^
       ------------------------------------------
       -- �ȉ��A���̎擾�p
       ------------------------------------------
      ,( --�z���於�擾�p�i�����敪�̒l�ɂ���Ď擾�悪�قȂ�j
           --�����敪��'2:�o��'�̏ꍇ�͔z���於���擾
           SELECT  2                              class                         --2_�z����
                  ,party_site_number              code                          --�z����No
                  ,party_site_name                name                          --�z���於
                  ,start_date_active              start_date_active             --�K�p�J�n��
                  ,end_date_active                end_date_active               --�K�p�I����
             FROM  xxsky_party_sites2_v                                         --�z������VIEW2
         UNION ALL
           --�����敪��'3:�x��'�̏ꍇ�͎����T�C�g�����擾
           SELECT  3                              class                         --3_�����
                  ,vendor_site_code               code                          --�d����T�C�gNo
                  ,vendor_site_name               name                          --�d����T�C�g��
                  ,start_date_active              start_date_active             --�K�p�J�n��
                  ,end_date_active                end_date_active               --�K�p�I����
             FROM  xxsky_vendor_sites2_v                                        --�d����T�C�g���VIEW2
       )                                          DELV                          --�z������擾�p
       ,xxsky_vendors2_v                          VNDR1                         --SKYLINK�p����VIEW �d������VIEW2(�d����)
       ,xxsky_vendors2_v                          VNDR2                         --SKYLINK�p����VIEW �d������VIEW2(������)
       ,xxsky_vendors2_v                          VNDR3                         --SKYLINK�p����VIEW �d������VIEW2(���_�����)
       ,xxsky_vendor_sites2_v                     VDST1                         --SKYLINK�p����VIEW �d����T�C�g���VIEW2(�d����T�C�g)
       ,xxsky_vendor_sites2_v                     VDST2                         --SKYLINK�p����VIEW �d����T�C�g���VIEW2(���_�H��)
       ,xxsky_locations2_v                        LOCT1                         --SKYLINK�p����VIEW ���Ə����VIEW2(�����掖�Ə�)
       ,xxsky_locations2_v                        LOCT2                         --SKYLINK�p����VIEW ���Ə����VIEW2(�����掖�Ə�)
       ,xxsky_locations2_v                        LOCT3                         --SKYLINK�p����VIEW ���Ə����VIEW2(����)
       ,xxsky_locations2_v                        LOCT4                         --SKYLINK�p����VIEW ���Ə����VIEW2(�˗��ҕ���)
       ,xxsky_locations2_v                        LOCT5                         --SKYLINK�p����VIEW ���Ə����VIEW2(�˗��敔��)
       ,xxsky_item_locations_v                    ILOC1                         --SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW2(�[����)
       ,xxsky_item_locations_v                    ILOC2                         --SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW2(���_���o�ɐ�)
       ,per_all_people_f                          PAPF1                         --�]�ƈ��}�X�^(�w���S���ҏ��擾�p)
       ,per_all_people_f                          PAPF2                         --�]�ƈ��}�X�^(�˗��Җ�)
       ,per_all_people_f                          PAPF3                         --�]�ƈ��}�X�^(���������Җ�)
       ,per_all_people_f                          PAPF4                         --�]�ƈ��}�X�^(�d�������Җ�)
       ,hr_all_organization_units_tl              HAOUT                         --�g�D�}�X�^(�g�D���擾�p)
       ,fnd_user                                  FU_CB_H                       --���[�U�[�}�X�^(created_by���̎擾�p)
       ,fnd_user                                  FU_LU_H                       --���[�U�[�}�X�^(last_updated_by���̎擾�p)
       ,fnd_user                                  FU_LL_H                       --���[�U�[�}�X�^(last_update_login���̎擾�p)
       ,fnd_logins                                FL_LL_H                       --���O�C���}�X�^(last_update_login���̎擾�p)
       ,fnd_lookup_values                         FLV01                         --�N�C�b�N�R�[�h(�����敪)
       ,fnd_lookup_values                         FLV02                         --�N�C�b�N�R�[�h(�����敪)
       ,fnd_lookup_values                         FLV03                         --�N�C�b�N�R�[�h(���_���ы敪)
 WHERE
   --�z������擾����
        POH.drop_ship_type                        = DELV.class(+)
   AND  POH.deliver_to                            = DELV.code(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= DELV.start_date_active(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= DELV.end_date_active(+)
   --�w���S���ҏ��擾
   AND  POH.pa_agent_id                           = PAPF1.person_id(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= PAPF1.effective_start_date(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= PAPF1.effective_end_date(+)
-- 2009/03/30 H.Iida Add Start �{�ԏ�Q#1346
   AND  NVL( PAPF1.attribute3, '1' )             IN ('1', '2')
-- 2009/03/30 H.Iida Add End
   --�d������擾
   AND  POH.vendor_id                             = VNDR1.vendor_id(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= VNDR1.start_date_active(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= VNDR1.end_date_active(+)
   --�d����T�C�g���擾
   AND  POH.vendor_site_id                        = VDST1.vendor_site_id(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= VDST1.start_date_active(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= VDST1.end_date_active(+)
   --�����掖�Ə����擾
   AND  POH.ship_to_location_id                   = LOCT1.location_id(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= LOCT1.start_date_active(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= LOCT1.end_date_active(+)
   --�����掖�Ə����擾
   AND  POH.bill_to_location_id                   = LOCT2.location_id(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= LOCT2.start_date_active(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= LOCT2.end_date_active(+)
   --�����Җ��擾����
   AND  POH.assist_id                             = VNDR2.vendor_id(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= VNDR2.start_date_active(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= VNDR2.end_date_active(+)
   --�[������擾
   AND  POH.deliver_in                            = ILOC1.segment1(+)
   --�������擾
   AND  POH.dept_code                             = LOCT3.location_code(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= LOCT3.start_date_active(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= LOCT3.end_date_active(+)
   --�g�D���擾
   AND  HAOUT.language(+)                         = 'JA'
   AND  POH.org_id                                = HAOUT.organization_id(+)
   --�˗��ҏ��擾
   AND  POH.requested_by_code                     = PAPF2.employee_number(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= PAPF2.effective_start_date(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= PAPF2.effective_end_date(+)
-- 2009/03/30 H.Iida Add Start �{�ԏ�Q#1346
   AND  PAPF2.attribute3                          IN ('1', '2')
-- 2009/03/30 H.Iida Add End
   --�˗��ҕ������擾
   AND  POH.requested_dept_code                   = LOCT4.location_code(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= LOCT4.start_date_active(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= LOCT4.end_date_active(+)
   --�˗��敔�����擾
   AND  POH.requested_to_dept_code                = LOCT5.location_code(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= LOCT5.start_date_active(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= LOCT5.end_date_active(+)
   --���������ҏ��擾
   AND  POH.order_approved_by                     = PAPF3.person_id(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= PAPF3.effective_start_date(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= PAPF3.effective_end_date(+)
-- 2009/03/30 H.Iida Add Start �{�ԏ�Q#1346
   AND  PAPF3.attribute3                          IN ('1', '2')
-- 2009/03/30 H.Iida Add End
   --���������ҏ��擾
   AND  POH.purchase_approved_by                  = PAPF4.person_id(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= PAPF4.effective_start_date(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= PAPF4.effective_end_date(+)
-- 2009/03/30 H.Iida Add Start �{�ԏ�Q#1346
   AND  PAPF4.attribute3                          IN ('1', '2')
-- 2009/03/30 H.Iida Add End
   --�����w�b�_��WHO�J�������擾
   AND  POH.h_created_by                          = FU_CB_H.user_id(+)
   AND  POH.h_last_updated_by                     = FU_LU_H.user_id(+)
   AND  POH.h_last_update_login                   = FL_LL_H.login_id(+)
   AND  FL_LL_H.user_id                           = FU_LL_H.user_id(+)
   --���_�������擾
   AND  POH.u_vendor_id                           = VNDR3.vendor_id(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= VNDR3.start_date_active(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= VNDR3.end_date_active(+)
   --���_�H����擾
   AND  POH.u_factory_id                          = VDST2.vendor_site_id(+)
   AND  NVL( POH.deliver_date, SYSDATE )         >= VDST2.start_date_active(+)
   AND  NVL( POH.deliver_date, SYSDATE )         <= VDST2.end_date_active(+)
   --���_���o�ɐ���擾
   AND  POH.u_loct_code                           = ILOC2.segment1(+)
   --�y�N�C�b�N�R�[�h�z�����敪���擾�p
   AND  FLV01.language(+)                         = 'JA'
   AND  FLV01.lookup_type(+)                      = 'XXPO_DROP_SHIP_TYPE'
   AND  FLV01.lookup_code(+)                      = POH.drop_ship_type
   --�y�N�C�b�N�R�[�h�z�����敪���擾�p
   AND  FLV02.language(+)                         = 'JA'
   AND  FLV02.lookup_type(+)                      = 'XXPO_PO_TYPE'
   AND  FLV02.lookup_code(+)                      = POH.po_type
   --�y�N�C�b�N�R�[�h�z�����敪���擾�p
   AND  FLV03.language(+)                         = 'JA'
   AND  FLV03.lookup_type(+)                      = 'XXPO_TXNS_TYPE'
   AND  FLV03.lookup_code(+)                      = POH.u_txns_type
/
COMMENT ON TABLE APPS.XXSKY_��������w�b�__��{_V IS 'SKYLINK�p��������w�b�_�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�����ԍ�              IS '�����ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.����ԕi�ԍ�          IS '����ԕi�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�X�e�[�^�X            IS '�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�X�e�[�^�X��          IS '�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�w���S���Ҕԍ�        IS '�w���S���Ҕԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�w���S���Җ�          IS '�w���S���Җ�'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�d����R�[�h          IS '�d����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�d���於              IS '�d���於'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�d����T�C�g�R�[�h    IS '�d����T�C�g�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�d����T�C�g��        IS '�d����T�C�g��'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�����掖�Ə��R�[�h    IS '�����掖�Ə��R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�����掖�Ə���        IS '�����掖�Ə���'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�����掖�Ə��R�[�h    IS '�����掖�Ə��R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�����掖�Ə���        IS '�����掖�Ə���'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�d���揳���v�t���O    IS '�d���揳���v�t���O'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�d���揳���v�t���O��  IS '�d���揳���v�t���O��'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�����҃R�[�h          IS '�����҃R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�����Җ�              IS '�����Җ�'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�[����                IS '�[����'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�[����R�[�h          IS '�[����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�[���於              IS '�[���於'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�����敪              IS '�����敪'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�����敪��            IS '�����敪��'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�z����R�[�h          IS '�z����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�z���於              IS '�z���於'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�˗��ԍ�              IS '�˗��ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�����R�[�h            IS '�����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.������                IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�����敪              IS '�����敪'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�����敪��            IS '�����敪��'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�w�b�_�E�v            IS '�w�b�_�E�v'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�g�D��                IS '�g�D��'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�˗��҃R�[�h          IS '�˗��҃R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�˗��Җ�              IS '�˗��Җ�'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�˗��ҕ����R�[�h      IS '�˗��ҕ����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�˗��ҕ�����          IS '�˗��ҕ�����'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�˗��敔���R�[�h      IS '�˗��敔���R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�˗��敔����          IS '�˗��敔����'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�˗���                IS '�˗���'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.���������t���O        IS '���������t���O'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�������F�t���O��      IS '�������F�t���O��'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.���������Ҕԍ�        IS '���������Ҕԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.���������Җ�          IS '���������Җ�'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�����������t          IS '�����������t'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�d�������t���O        IS '�d�������t���O'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�d�������t���O��      IS '�d�������t���O��'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�d���������[�U�[�ԍ�  IS '�d���������[�U�[�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�d���������[�U�[��    IS '�d���������[�U�[��'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�d���������t          IS '�d���������t'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�ύX�t���O            IS '�ύX�t���O'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�ύX�t���O��          IS '�ύX�t���O��'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.����_�쐬��           IS '����_�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.����_�쐬��           IS '����_�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.����_�ŏI�X�V��       IS '����_�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.����_�ŏI�X�V��       IS '����_�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.����_�ŏI�X�V���O�C�� IS '����_�ŏI�X�V���O�C��'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.���_���ы敪         IS '���_���ы敪'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.���_���ы敪��       IS '���_���ы敪��'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.���_�x���˗��ԍ�     IS '���_�x���˗��ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.���_�����R�[�h     IS '���_�����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.���_����於         IS '���_����於'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.���_�H��R�[�h       IS '���_�H��R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.���_�H�ꖼ           IS '���_�H�ꖼ'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.���_���o�ɐ�R�[�h   IS '���_���o�ɐ�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.���_���o�ɐ於       IS '���_���o�ɐ於'
/
COMMENT ON COLUMN APPS.XXSKY_��������w�b�__��{_V.�ԕi�w�b�_�E�v        IS '�ԕi�w�b�_�E�v'
/
