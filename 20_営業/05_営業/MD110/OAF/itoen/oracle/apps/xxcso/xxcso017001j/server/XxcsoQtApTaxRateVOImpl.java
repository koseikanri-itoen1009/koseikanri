/*============================================================================
* �t�@�C���� : XxcsoQtApTaxRateVOImpl
* �T�v����   : �����ŗ��擾�p�r���[�N���X
* �o�[�W���� : 1.2
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2011-05-17 1.0  SCS�ː��a�K  �V�K�쐬
* 2013-08-20 1.1  SCSK����O�� �yE_�{�ғ�_10884�z����ő��őΉ�
* 2019-06-11 1.2  SCSK�������� �yE_�{�ғ�_15472�z�y���ŗ��Ή�
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
// 2013-08-20 Ver1.1 [E_�{�ғ�_10884] Add Start
import oracle.jbo.domain.Date;
// 2013-08-20 Ver1.1 [E_�{�ғ�_10884] Add End
/*******************************************************************************
 * �����ŗ��擾�̃r���[�N���X�ł��B
 * @author  SCS�ː��a�K
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQtApTaxRateVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQtApTaxRateVOImpl()
  {
  }
// 2013-08-20 Ver1.1 [E_�{�ғ�_10884] Add Start
  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param getDate ����Ŏ擾���
   * @param InventoryItemCode �i�ڃR�[�h
   *****************************************************************************
   */
  public void initQuery(
    Date getDate
// 2019-06-11 Ver1.2 [E_�{�ғ�_15472] Add Start
  , String InventoryItemCode
// 2019-06-11 Ver1.2 [E_�{�ғ�_15472] Add End
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, getDate);
// 2019-06-11 Ver1.2 [E_�{�ғ�_15472] Add Start
    setWhereClauseParam(1, getDate);
    setWhereClauseParam(2, getDate);
    setWhereClauseParam(3, InventoryItemCode);
    setWhereClauseParam(4, getDate);
    setWhereClauseParam(5, getDate);
    setWhereClauseParam(6, getDate);
// 2019-06-11 Ver1.2 [E_�{�ғ�_15472] Add End

    executeQuery();

  }
// 2013-08-20 Ver1.1 [E_�{�ғ�_10884] Add End
}