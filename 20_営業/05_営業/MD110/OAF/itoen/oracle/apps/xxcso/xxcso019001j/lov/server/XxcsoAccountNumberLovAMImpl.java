/*============================================================================
* t@C¼ : XxcsoAccountNumberLovAMImpl
* Tvà¾   : KâEãvææÊ@ÚqR[hknuAvP[VW[NX
* o[W : 1.0
*============================================================================
* C³ð
* út       Ver. SÒ       C³àe
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCSpMF@  VKì¬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019001j.lov.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;

/*******************************************************************************
 * KâEãvææÊ@ÚqR[hknuAvP[VW[NX
 * @author  SCSpMF
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoAccountNumberLovAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoAccountNumberLovAMImpl()
  {
  }

  /**
   * 
   * Container's getter for XxcsoAccountNumberLovVO1
   */
  public XxcsoAccountNumberLovVOImpl getXxcsoAccountNumberLovVO1()
  {
    return (XxcsoAccountNumberLovVOImpl)findViewObject("XxcsoAccountNumberLovVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso019001j.lov.server", "XxcsoAccountNumberLovAMLocal");
  }
}