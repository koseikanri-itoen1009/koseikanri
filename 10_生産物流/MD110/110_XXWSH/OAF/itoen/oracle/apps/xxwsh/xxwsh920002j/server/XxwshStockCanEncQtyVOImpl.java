/*============================================================================
* �t�@�C���� : XxwshStockCanEncQtyVOImpl
* �T�v����   : �莝���E�����\���ꗗ���[�W�����r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-17 1.0  �k�������v     �V�K�쐬
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
 * �莝���E�����\���ꗗ���[�W�����r���[�I�u�W�F�N�g�N���X�ł��B
 * @author  ORACLE �k���� ���v
 * @version 1.0
 ***************************************************************************
 */
public class XxwshStockCanEncQtyVOImpl extends OAViewObjectImpl
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwshStockCanEncQtyVOImpl()
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
 
      // WHERE���������
      setWhereClauseParams(null); // Always reset
      setOrderByClause(null);
      setWhereClause(null);
      // �o�C���h�ϐ��ɒl���Z�b�g
      setWhereClauseParam(0,  lotCtl);                   // ���b�g�Ǘ�     
      setWhereClauseParam(1,  scheduleShipDate);         // �o�ɗ\���
      setWhereClauseParam(2,  scheduleShipDate);         // �o�ɗ\���
      setWhereClauseParam(3,  inputInventoryLocationId); // ���͕ۊǑq��ID
      setWhereClauseParam(4,  lotCtl);                   // ���b�g�Ǘ�
      setWhereClauseParam(5,  scheduleShipDate);         // �o�ɗ\���
      setWhereClauseParam(6,  inputInventoryLocationId); // ���͕ۊǑq��ID
      setWhereClauseParam(7,  lotCtl);                   // ���b�g�Ǘ�
      setWhereClauseParam(8,  convUnitUseKbn);           // ���o�Ɋ��Z�P�ʎg�p�敪
      setWhereClauseParam(9,  inputInventoryLocationId); // ���͕ۊǑq��ID
      setWhereClauseParam(10, lotCtl);                   // ���b�g�Ǘ�
      setWhereClauseParam(11, scheduleShipDate);         // �o�ɗ\���
      setWhereClauseParam(12, numOfCases);               // �P�[�X����
      setWhereClauseParam(13, inputInventoryLocationId); // ���͕ۊǑq��ID
      setWhereClauseParam(14, lotCtl);                   // ���b�g�Ǘ�
      setWhereClauseParam(15, scheduleShipDate);         // �o�ɗ\���
      setWhereClauseParam(16, convUnitUseKbn);           // ���o�Ɋ��Z�P�ʎg�p�敪
      setWhereClauseParam(17, inputInventoryLocationId); // ���͕ۊǑq��ID
      setWhereClauseParam(18, lotCtl);                   // ���b�g�Ǘ�
      setWhereClauseParam(19, numOfCases);               // �P�[�X����
      setWhereClauseParam(20, inputInventoryLocationId); // ���͕ۊǑq��ID
      setWhereClauseParam(21, lotCtl);                   // ���b�g�Ǘ�
      setWhereClauseParam(22, convUnitUseKbn);           // ���o�Ɋ��Z�P�ʎg�p�敪
      setWhereClauseParam(23, numOfCases);               // �P�[�X����
      setWhereClauseParam(24, itemId);                   // �i��ID
      setWhereClauseParam(25, prodClass);                // ���i�敪
      setWhereClauseParam(26, lineId);                   // ����ID
      setWhereClauseParam(27, documentTypeCode);         // �����^�C�v
      setWhereClauseParam(28, inputInventoryLocationId); // ���͕ۊǑq��ID
      setWhereClauseParam(29, lotCtl);                   // ���b�g�Ǘ�
      setWhereClauseParam(30, scheduleShipDate);         // �o�ɗ\���
      // ���b�g�Ǘ��i�̏ꍇ�������Z�b�g
      if (XxwshConstants.LOT_CTL_Y.equals(lotCtl.toString()))
      {
        //WHERE��쐬
        StringBuffer whereClause   = new StringBuffer(1000);  // WHERE��쐬�p�I�u�W�F�N�g
        //ORDERBY�吶��
        StringBuffer orderByClause = new StringBuffer(1000);  // ORDERBY��쐬�p�I�u�W�F�N�g
        //�����Ƀ��b�g�Ǘ��i��ǉ�
        whereClause.append("lot_id <> " + XxwshConstants.DEFAULT_LOT.toString());

        //�w�萻���������͂���Ă���ꍇ������ǉ�
        if (!XxcmnUtility.isBlankOrNull(designatedProductionDate))
        {
          XxcmnUtility.andAppend(whereClause);
          // Where�吶��
          whereClause.append("production_date >= '" + designatedProductionDate + "'");
        }
        //�ďo��ʋ敪���u�o�ׁv�ŋ��_���їL���敪���u���㋒�_�v�̏ꍇ������ǉ�
        if (XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn) &
           XxwshConstants.LOCATION_REL_CODE_SALE.equals(locationRelCode))
        {
          XxcmnUtility.andAppend(whereClause);
          // Where�吶��
          whereClause.append("ship_req_m_reserve = 'Y'");
        }
        // �ďo��ʋ敪���u�x���v�̏ꍇ������ǉ�
        else if(XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn))
        {
          XxcmnUtility.andAppend(whereClause);
          // Where�吶��
          whereClause.append("pay_provision_m_reserve = 'Y'");
        }
        // �ďo��ʋ敪���u�ړ��v�̏ꍇ������ǉ�
        else if(XxwshConstants.CALL_PIC_KBN_MOVE_ORDER.equals(callPictureKbn))
        {
          XxcmnUtility.andAppend(whereClause);
          // Where�吶��
          whereClause.append("move_inst_m_reserve = 'Y'");
        }
        // ORDER BY���ݒ�
        // �i�ڋ敪�����i�̏ꍇ
        if (XxwshConstants.ITEM_TYPE_PROD.equals(itemClass))
        {
          // Order BY�吶��
          orderByClause.append(" production_date asc "); // ������(����)
          orderByClause.append(",expiration_date asc "); // �ܖ�����(����)
          orderByClause.append(",uniqe_sign asc ");      // �ŗL�L��(����)
        } else
        {
          // Order BY�吶��
          orderByClause.append(" show_lot_no asc ");     // ���b�gNo(����)
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