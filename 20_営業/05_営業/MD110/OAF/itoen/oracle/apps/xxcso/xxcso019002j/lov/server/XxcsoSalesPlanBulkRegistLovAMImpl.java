/*============================================================================
* �t�@�C���� : XxcsoSalesPlanBulkRegistLovAM
* �T�v����   : �S���c�ƈ�LOV�p�A�v���P�[�V�����E���W���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-04-22 1.0  SCS�������l  �V�K�쐬([ST��QT1_0585]�ɂ��ǉ�)
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019002j.lov.server;

import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

/*******************************************************************************
 * �S���c�ƈ�LOV�̃A�v���P�[�V�����E���W���[���N���X
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesPlanBulkRegistLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesPlanBulkRegistLovAMImpl()
  {
  }

  /**
   * 
   * Container's getter for SalesPlanResorcesLovVO
   */
  public XxcsoSalesPlanResorcesLovVOImpl getSalesPlanResorcesLovVO()
  {
    return (XxcsoSalesPlanResorcesLovVOImpl)findViewObject("SalesPlanResorcesLovVO");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso019002j.lov.server", "XxcsoSalesPlanBulkRegistLovAMLocal");
  }
}