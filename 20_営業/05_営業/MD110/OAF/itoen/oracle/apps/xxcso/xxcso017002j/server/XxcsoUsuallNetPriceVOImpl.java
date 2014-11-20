/*============================================================================
* �t�@�C���� : XxcsoUsuallyDelivPriceVOImpl
* �T�v����   : �ʏ�NET���i�r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2011-04-13 1.0  SCS�g������  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017002j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * �ʏ�NET���i�𓱏o���邽�߂̃r���[�N���X�ł��B
 * @author  SCS�g������
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoUsuallNetPriceVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoUsuallNetPriceVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param AccountNumber       �ڋq�R�[�h
   * @param InventoryItemId     �i�ڂh�c
   * @param QuoteDiv            ���ϋ敪
   * @param UsuallyDelivPrice   �ʏ�X�[���i
   *****************************************************************************
   */
  public void initQuery(
    String AccountNumber,     // �ڋq�R�[�h
    Number InventoryItemId,   // �i��ID
    String UsuallyDelivPrice  // �ʏ�X�[���i
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;
    setWhereClauseParam(index++, AccountNumber);
    setWhereClauseParam(index++, InventoryItemId);
    setWhereClauseParam(index++, UsuallyDelivPrice);   

    executeQuery();
  }

}