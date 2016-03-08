/*============================================================================
* �t�@�C���� : XxwshReserveLotVOImpl
* �T�v����   : �莝���E�����\���ꗗ(���b�g�Ǘ��i)���[�W�����r���[�I�u�W�F�N�g
* �o�[�W���� : 1.3
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-25 1.0  ��r�@���     �V�K�쐬 �{��#771�Ή�
* 2009-12-04 1.1  �ɓ�  �ЂƂ�   �{�ғ���Q#11�Ή�
* 2010-01-05 1.2  �ɓ�  �ЂƂ�   �{�ғ���Q#861�Ή�
* 2016-02-18 1.3  �R��  �đ�     E_�{�ғ�_13468�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxwsh.xxwsh920002j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxwsh.util.XxwshConstants;
import com.sun.java.util.collections.HashMap;

/***************************************************************************
 * �莝���E�����\���ꗗ(���b�g�Ǘ��i)���[�W�����r���[�I�u�W�F�N�g�N���X�ł��B
 * @author  ORACLE ��r�@���
 * @version 1.3
 ***************************************************************************
 */
public class XxwshReserveLotVOImpl extends OAViewObjectImpl
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwshReserveLotVOImpl()
  {
  }
  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param params - �����L�[
   ****************************************************************************/
  public void initQuery(
    HashMap params)
  {
    // �����L�[���w�肳��Ă���ꍇ�Ɍ��������s
    if (!XxcmnUtility.isBlankOrNull(params))
    {

      // HashMap����l���擾
      Number itemId                     = (Number)params.get("ItemId");                     // �i��ID
      Number inputInventoryLocationId   = (Number)params.get("InputInventoryLocationId");   // �ۊǑq��ID
      String inputInventoryLocationCode = (String)params.get("InputInventoryLocationCode"); // �ۊǑq�ɃR�[�h
      String documentTypeCode           = (String)params.get("DocumentTypeCode");           // �����^�C�v
      String locationRelCode            = (String)params.get("LocationRelCode");            // ���_���їL���敪
      String convUnitUseKbn             = (String)params.get("ConvUnitUseKbn");             // ���o�Ɋ��Z�P�ʎg�p�敪
      String callPictureKbn             = (String)params.get("CallPictureKbn");             // �ďo��ʋ敪
      Number lotCtl                     = (Number)params.get("LotCtl");                     // ���b�g�Ǘ��i
      String designatedProductionDate   = (String)params.get("DesignatedProductionDate");   // �w�萻����
      Number lineId                     = (Number)params.get("LineId");                     // ����ID
      Date scheduleShipDate             = (Date)params.get("ScheduleShipDate");             // �o�ח\���
      String prodClass                  = (String)params.get("ProdClass");                  // ���i�敪
      String itemClass                  = (String)params.get("ItemClass");                  // �i�ڋ敪
      String numOfCases                 = (String)params.get("NumOfCases");                 // �P�[�X����
      String frequentWhseCode           = (String)params.get("FrequentWhseCode");            // ��\�q��
      String masterOrgId                = (String)params.get("MasterOrgId");                 // �݌ɑg�DID
      String maxDate                    = (String)params.get("MaxDate");                     // �ő���t
      String dummyFrequentWhse          = (String)params.get("DummyFrequentWhse");           // �_�~�[�q��
// 2009-12-04 H.Itou Add Start �{�ғ���Q#11
      String openDate                   = (String)params.get("OpenDate");                    // �I�[�v�����t
// 2009-12-04 H.Itou Add End �{�ғ���Q#11
 
      // WHERE���������
      setWhereClauseParams(null); // Always reset
      setOrderByClause(null);
      setWhereClause(null);
      // �o�C���h�ϐ��ɒl���Z�b�g
      int i = 0;
// 2009-12-04 H.Itou Del Start �{�ғ���Q#11 ���Z�̓f�[�^�擾��s�����߁B
//      setWhereClauseParam(i++, convUnitUseKbn);             //  0:���o�Ɋ��Z�P�ʎg�p�敪
//      setWhereClauseParam(i++, numOfCases);                 //  1:�P�[�X����
//      setWhereClauseParam(i++, convUnitUseKbn);             //  2:���o�Ɋ��Z�P�ʎg�p�敪
//      setWhereClauseParam(i++, numOfCases);                 //  3:�P�[�X����
// 2009-12-04 H.Itou Del End
      setWhereClauseParam(i++, lotCtl);                     //  0:���b�g�Ǘ�
// 2009-12-04 H.Itou Add Start �{�ғ���Q#11
      setWhereClauseParam(i++, scheduleShipDate);           //  1:�o�ɗ\���
      setWhereClauseParam(i++, scheduleShipDate);           //  2:�o�ɗ\���
// 2009-12-04 H.Itou Add End �{�ғ���Q#11
      setWhereClauseParam(i++, lotCtl);                     //  3:���b�g�Ǘ�
      setWhereClauseParam(i++, masterOrgId);                //  4:�݌ɑg�DID
      setWhereClauseParam(i++, scheduleShipDate);           //  5:�o�ɗ\���
      setWhereClauseParam(i++, maxDate);                    //  6:�ő���t
      setWhereClauseParam(i++, inputInventoryLocationId);   //  7:���͕ۊǑq��ID
      setWhereClauseParam(i++, inputInventoryLocationCode); //  8:���͕ۊǑq�ɃR�[�h
      setWhereClauseParam(i++, frequentWhseCode);           //  9:��\�q��
      setWhereClauseParam(i++, dummyFrequentWhse);          // 10:�_�~�[�q��
      setWhereClauseParam(i++, lotCtl);                     // 11:���b�g�Ǘ�
      setWhereClauseParam(i++, inputInventoryLocationId);   // 12:���͕ۊǑq��ID
      setWhereClauseParam(i++, convUnitUseKbn);             // 13:���o�Ɋ��Z�P�ʎg�p�敪
      setWhereClauseParam(i++, numOfCases);                 // 14:�P�[�X����
// 2009-12-04 H.Itou Add Start �{�ғ���Q#11
      setWhereClauseParam(i++, itemId);                     // 15:�i��ID
      setWhereClauseParam(i++, openDate);                   // 16:�I�[�v�����t
      setWhereClauseParam(i++, itemId);                     // 17:�i��ID
      setWhereClauseParam(i++, itemId);                     // 18:�i��ID
      setWhereClauseParam(i++, masterOrgId);                // 19:�݌ɑg�DID
      setWhereClauseParam(i++, openDate);                   // 20:�I�[�v�����t
      setWhereClauseParam(i++, itemId);                     // 21:�i��ID
      setWhereClauseParam(i++, openDate);                   // 22:�I�[�v�����t
      setWhereClauseParam(i++, openDate);                   // 23:�I�[�v�����t
      setWhereClauseParam(i++, itemId);                     // 24:�i��ID
      setWhereClauseParam(i++, itemId);                     // 25:�i��ID
      setWhereClauseParam(i++, openDate);                   // 26:�I�[�v�����t
// 2010-01-05 H.Itou Add Start �{�ғ���Q#861
      setWhereClauseParam(i++, itemId);                     // 27:�i��ID
      setWhereClauseParam(i++, openDate);                   // 28:�I�[�v�����t
// 2010-01-05 H.Itou Add End �{�ғ���Q#861
      setWhereClauseParam(i++, lineId);                     // 29:����ID
      setWhereClauseParam(i++, documentTypeCode);           // 30:�����^�C�v
// 2009-12-04 H.Itou Add End �{�ғ���Q#11
      setWhereClauseParam(i++, itemId);                     // 31:�i��ID
      setWhereClauseParam(i++, prodClass);                  // 32:���i�敪
      setWhereClauseParam(i++, lineId);                     // 33:����ID
      setWhereClauseParam(i++, documentTypeCode);           // 34:�����^�C�v
// 2009-12-04 H.Itou Del Start �{�ғ���Q#11 ��Ɉړ��B
//      setWhereClauseParam(i++, scheduleShipDate);           // 21:�o�ɗ\���
//      setWhereClauseParam(i++, scheduleShipDate);           // 22:�o�ɗ\���
// 2009-12-04 H.Itou Del End �{�ғ���Q#11

      // ���b�g�Ǘ��i�̏ꍇ�������Z�b�g
      if (XxwshConstants.LOT_CTL_Y.equals(lotCtl.toString()))
      {
        //WHERE��쐬
        StringBuffer whereClause   = new StringBuffer(1000);  // WHERE��쐬�p�I�u�W�F�N�g
        //ORDERBY�吶��
        StringBuffer orderByClause = new StringBuffer(1000);  // ORDERBY��쐬�p�I�u�W�F�N�g
        //�����Ƀ��b�g�Ǘ��i��ǉ�
        whereClause.append(" lot_id <> " + XxwshConstants.DEFAULT_LOT.toString());

        //�w�萻���������͂���Ă���ꍇ������ǉ�
        if (!XxcmnUtility.isBlankOrNull(designatedProductionDate))
        {
          XxcmnUtility.andAppend(whereClause);
          // Where�吶��
          whereClause.append(" production_date >= '" + designatedProductionDate + "'");
        }
        //�ďo��ʋ敪���u�o�ׁv�ŋ��_���їL���敪���u���㋒�_�v�̏ꍇ������ǉ�
        if (XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn) &
           XxwshConstants.LOCATION_REL_CODE_SALE.equals(locationRelCode))
        {
          XxcmnUtility.andAppend(whereClause);
          // Where�吶��
          whereClause.append(" ship_req_m_reserve = 'Y'");
        }
        // �ďo��ʋ敪���u�x���v�̏ꍇ������ǉ�
        else if(XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn))
        {
          XxcmnUtility.andAppend(whereClause);
          // Where�吶��
          whereClause.append(" pay_provision_m_reserve = 'Y'");
        }
        // �ďo��ʋ敪���u�ړ��v�̏ꍇ������ǉ�
        else if(XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn))
        {
          XxcmnUtility.andAppend(whereClause);
          // Where�吶��
          whereClause.append(" move_inst_m_reserve = 'Y'");
        }
        // ORDER BY���ݒ�
        // �i�ڋ敪�����i�̏ꍇ
        if (XxwshConstants.ITEM_TYPE_PROD.equals(itemClass))
        {
          // Order BY�吶��
// 2016-02-18 S.Yamashita Mod Start E_�{�ғ�_13468
//          orderByClause.append(" production_date asc "); // ������(����)
          orderByClause.append(" expiration_date asc "); // �ܖ�����(����)
          orderByClause.append(",production_date asc "); // ������(����)
// 2016-02-18 S.Yamashita Mod End   E_�{�ғ�_13468
          orderByClause.append(",uniqe_sign asc ");      // �ŗL�L��(����)
        } else
        {
          // Order BY�吶��
          orderByClause.append(" TO_NUMBER(show_lot_no) asc ");     // ���b�gNo(����)
        }
        //�ǉ������������Z�b�g
        setWhereClause(whereClause.toString());
        // ORDER BY �������Z�b�g
        setOrderByClause(orderByClause.toString());
      }
      //���������s
      executeQuery();
    }
  }
}