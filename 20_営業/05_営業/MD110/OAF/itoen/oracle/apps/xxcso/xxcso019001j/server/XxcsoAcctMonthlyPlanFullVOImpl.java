/*============================================================================
* �t�@�C���� : XxcsoAcctMonthlyPlanFullVOImpl
* �T�v����   : �K��E����v���ʁ@�ڋq�ʔ���v�挎�ʃ��[�W�����r���[�N���X
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
 * �K��E����v���ʁ@�ڋq�ʔ���v�挎�ʃ��[�W�����r���[�N���X
 * @author  SCS�p�M�F
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoAcctMonthlyPlanFullVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoAcctMonthlyPlanFullVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param baseCode        ���_�R�[�h
   * @param accountNumber   �ڋq�R�[�h
   * @param planYearMonth   �v��N��
   *****************************************************************************
   */
  public void initQuery(
    String baseCode
   ,String accountNumber
   ,String planYearMonth
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;
    
    setWhereClauseParam(index++, baseCode);
    setWhereClauseParam(index++, accountNumber);
    setWhereClauseParam(index++, planYearMonth);

    executeQuery();
  }
}