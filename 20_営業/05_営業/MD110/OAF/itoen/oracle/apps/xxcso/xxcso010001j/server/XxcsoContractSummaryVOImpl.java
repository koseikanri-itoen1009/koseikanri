/*============================================================================
* �t�@�C���� : XxcsoContractSummaryVOImpl
* �T�v����   : �_�񏑖��׃r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-10-31 1.0  SCS�y���    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/*******************************************************************************
 * �_�񏑖��ׂ��o�͂��邽�߂̃r���[�N���X�ł��B
 * @author  SCS�y���
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractSummaryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractSummaryVOImpl()
  {
  }
  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param Contractnumber         �_�񏑔ԍ�
   * @param Installaccountnumber   �ڋq�R�[�h
   * @param Installpartyname       �ݒu�於
   *****************************************************************************
   */
  public void initQuery(
    String Contractnumber,
    String Installaccountnumber,
    String Installpartyname
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;
    setWhereClauseParam(index++, Contractnumber);
    setWhereClauseParam(index++, Contractnumber);
    setWhereClauseParam(index++, Contractnumber);
    setWhereClauseParam(index++, Installaccountnumber);
    setWhereClauseParam(index++, Installaccountnumber);
    setWhereClauseParam(index++, Installaccountnumber);
    setWhereClauseParam(index++, Installpartyname);
    setWhereClauseParam(index++, Installpartyname);
    setWhereClauseParam(index++, Installpartyname);

    executeQuery();
  }
}