/*============================================================================
* �t�@�C���� : XxcsoAcctSalesSummaryVOImpl
* �T�v����   : �K��E����v���ʁ@�ڋq�������ʕ\�����[�W�����r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS�p�M�F�@  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * �K��E����v���ʁ@�ڋq�������ʕ\�����[�W�����r���[�N���X
 * @author  SCS�p�M�F
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoAcctSalesSummaryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoAcctSalesSummaryVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param accountNumber   �ڋq�R�[�h
   * @param partyName       �ڋq��
   * @param partyId         �p�[�e�BID
   * @param vistTargetDiv   �K��Ώۋ敪
   * @param planYear        �v��N
   * @param planMonth       �v�挎
   *****************************************************************************
   */
  public void initQuery(
    String accountNumber
   ,String partyName
   ,String partyId
   ,String vistTargetDiv
   ,String planYear
   ,String planMonth
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;
    
    setWhereClauseParam(index++, accountNumber);
    setWhereClauseParam(index++, partyName);
    setWhereClauseParam(index++, partyId);
    setWhereClauseParam(index++, vistTargetDiv);
    setWhereClauseParam(index++, planYear);
    setWhereClauseParam(index++, planMonth);

    executeQuery();
  }
}