/*============================================================================
* �t�@�C���� : XxcsoUsuallyDelivPriceVOImpl
* �T�v����   : �ʏ�X�[���i�r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-11 1.0  SCS�y���    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Number;
/*******************************************************************************
 * �ʏ�X�[���i���o�͂��邽�߂̃r���[�N���X�ł��B
 * @author  SCS�y���
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoUsuallyDelivPriceVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoUsuallyDelivPriceVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param AccountNumber       �ڋq�R�[�h
   * @param InventoryItemId     �i�ڂh�c
   *****************************************************************************
   */
  public void initQuery(
    String AccountNumber,
    Number InventoryItemId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;
    setWhereClauseParam(index++, AccountNumber);
    setWhereClauseParam(index++, InventoryItemId);

    executeQuery();
  }

}